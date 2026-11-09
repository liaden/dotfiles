#!/usr/bin/env ruby
# frozen_string_literal: true

# Interleaved A/B of shell commands, 1 fresh process per trial.
#
#   ab.rb [--n 20] [--seed N] [--out trials.ndjson] [--timeout SECONDS] [--no-nice] [--no-cwd-pad] control='cmd' treatment='cmd' ...
#
# A command reports its own number by printing `ms=<float>` (any unit works, the name is fixed);
# the last such line wins. With none, the trial's value is the process wall in ms.
# A command may print `digest=<text>`; arms that disagree fail the run.
# A trial that exits non-zero or passes --timeout is recorded, left out of the medians, and fails the run at the end.
# Each trial gets a random-size AB_PAD variable and a working directory of random path length, so use absolute
# paths in the commands; a `cd` inside a command undoes the directory part.
# The first arm is the control. Stdlib only.
require "json"
require "open3"
require "optparse"
require "tmpdir"

module AB
  PAD_MAX = 4096
  PAD_BUCKETS = 4
  BUCKET_MIN = 3
  CWD_MAX = 200
  RESAMPLES = 10_000
  # An arm that runs `bundle exec` in another tree must resolve that tree's Gemfile, not the caller's.
  INHERITED = /\A(BUNDLE_|RUBYOPT\z|RUBYLIB\z)/

  module_function

  def median(values)
    sorted = values.sort
    mid = sorted.size / 2
    sorted.size.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
  end

  def quartiles(values)
    sorted = values.sort
    [0.25, 0.75].map do |q|
      pos = q * (sorted.size - 1)
      low = sorted[pos.floor]
      low + ((sorted[pos.ceil] - low) * (pos - pos.floor))
    end
  end

  def ratio_ci(control, treatment, rng)
    ratios = Array.new(RESAMPLES) do
      median(treatment.map { treatment.sample(random: rng) }) / median(control.map { control.sample(random: rng) })
    end.sort
    [ratios[(RESAMPLES * 0.025).floor], ratios[(RESAMPLES * 0.975).ceil - 1]]
  end

  # Share of (treatment, control) pairs where treatment is larger, minus the share where it is smaller.
  def cliff(control, treatment)
    pairs = treatment.product(control)
    pairs.sum { |t, c| t <=> c }.fdiv(pairs.size)
  end

  # `uptime` prints the load on Linux and macOS alike; /proc is Linux only.
  def load = `uptime`[/load averages?:\s*([\d.]+)/, 1].to_f

  def child_env(pad)
    ENV.keys.grep(INHERITED).to_h { [_1, nil] }.merge("AB_PAD" => "x" * pad)
  end

  def capture(env, argv, timeout, cwd)
    Open3.popen3(env, *argv, pgroup: true, chdir: cwd) do |stdin, stdout, stderr, waiter|
      stdin.close
      readers = [stdout, stderr].map { |io| Thread.new { io.read } }
      timed_out = waiter.join(timeout).nil?
      Process.kill("KILL", -waiter.pid) if timed_out
      [*readers.map(&:value), waiter.value, timed_out]
    end
  end

  def failure(arm, err, status, timed_out, timeout)
    return "#{arm} timed out after #{timeout}s" if timed_out

    "#{arm} exited #{status.exitstatus}\n#{err}" unless status.success?
  end

  def padded_cwd(base, rng)
    return Dir.pwd unless base

    File.join(base, "x" * rng.rand(1..CWD_MAX)).tap { Dir.mkdir(_1) unless Dir.exist?(_1) }
  end

  def trial(arm, command, round, rng, nice:, timeout:, cwd_base:)
    # Environment size moves stack alignment enough to reverse a small difference (Mytkowicz et al., ASPLOS 09).
    pad = rng.rand(PAD_MAX)
    cwd = padded_cwd(cwd_base, rng)
    argv = nice ? ["nice", "-n", "10", "bash", "-c", command] : ["bash", "-c", command]
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    out, err, status, timed_out = capture(child_env(pad), argv, timeout, cwd)
    wall = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000
    failed = failure(arm, err, status, timed_out, timeout)
    warn failed if failed
    { arm:, round:, pad:, cwd:, cwd_len: cwd.size, ok: failed.nil?, value: out.scan(/^ms=([\d.eE+-]+)/).flatten.last&.to_f || wall,
      wall: wall.round(2), digest: out[/^digest=(.*)/, 1], load: }
  end

  def run(arms, rounds:, rng:, log:, **)
    Array.new(rounds) do |round|
      arms.to_a.shuffle(random: rng).map do |arm, command|
        trial(arm, command, round, rng, **).tap { log&.puts(JSON.generate(_1)) }
      end
    end.flatten
  end

  # How far the pad alone moves an arm's typical value: the widest gap between the medians of its pad-size buckets.
  def pad_spread(records)
    buckets = records.group_by { _1[:pad] * PAD_BUCKETS / PAD_MAX }.values.select { _1.size >= BUCKET_MIN }
    return if buckets.size < 2

    medians = buckets.map { |bucket| median(bucket.map { _1[:value] }) }
    medians.max - medians.min
  end

  def arm_line(arm, records)
    values = records.map { _1[:value] }
    low, high = quartiles(values)
    spread = pad_spread(records)
    format("%-12s %3d  %10.3f  %10.3f  %10.3f  %10.3f  %5.1f  %10s", arm, values.size, median(values), high - low,
           values.min, values.max, median(records.map { _1[:load] }), spread ? format("%.3f", spread) : "-")
  end

  def verdict(interval, shift, spreads)
    return "not shown" if interval.first <= 1 && interval.last >= 1

    shift.abs > spreads.compact.max.to_f ? "differs" : "within layout"
  end

  def comparison_line(name, control, treatment, rng)
    values = [control, treatment].map { |records| records.map { _1[:value] } }
    interval = ratio_ci(*values, rng)
    shift = median(values.last) - median(values.first)
    format("%-24s %6.3f  [%.3f, %.3f]  %-13s  cliff %+.2f", name, median(values.last) / median(values.first), *interval,
           verdict(interval, shift, [control, treatment].map { pad_spread(_1) }), cliff(*values))
  end

  def report(records, arms, rng)
    by_arm = arms.keys.to_h { |arm| [arm, records.select { _1[:arm] == arm }] }
    return puts("no passing trials for: #{by_arm.select { _2.empty? }.keys.join(", ")}") if by_arm.value?([])

    puts format("%-12s %3s  %10s  %10s  %10s  %10s  %5s  %10s", "arm", "n", "median", "iqr", "min", "max", "load",
                "pad spread")
    arms.each_key { |arm| puts arm_line(arm, by_arm.fetch(arm)) }
    control, *treatments = arms.keys
    puts "", format("%-24s %6s  %-16s  %-13s", "comparison", "ratio", "ci95", "verdict")
    treatments.each do |arm|
      puts comparison_line("#{arm} vs #{control}", by_arm[control], by_arm[arm], rng)
    end
  end

  def check_digests(records)
    digests = records.filter_map { _1[:digest] }.tally
    abort "digests differ between trials: #{digests}" if digests.size > 1
  end

  def check_failures(failed)
    return if failed.empty?

    puts "", "failed trials: #{failed.map { _1[:arm] }.tally.map { |arm, count| "#{arm} #{count}" }.join(", ")}"
    exit 1
  end

  def main(argv)
    options = { n: 20, seed: Random.new_seed % 1_000_000, nice: true, timeout: nil, cwd_pad: true }
    parser = OptionParser.new do |o|
      o.on("--n N", Integer) { options[:n] = _1 }
      o.on("--seed N", Integer) { options[:seed] = _1 }
      o.on("--out FILE") { options[:out] = _1 }
      o.on("--timeout SECONDS", Float) { options[:timeout] = _1 }
      o.on("--no-nice") { options[:nice] = false }
      o.on("--no-cwd-pad") { options[:cwd_pad] = false }
    end
    arms = parser.parse(argv).to_h { _1.split("=", 2) }
    abort "usage: ab.rb [--n 20] [--seed N] [--out FILE] [--timeout SECONDS] [--no-cwd-pad] control='cmd' treatment='cmd' ..." if arms.size < 2
    rng = Random.new(options[:seed])
    log = options[:out] && File.open(options[:out], "a")
    cwd_base = Dir.mktmpdir("ab-cwd") if options[:cwd_pad]
    passed, failed = run(arms, rounds: options[:n], rng:, log:, cwd_base:, **options.slice(:nice, :timeout)).partition { _1[:ok] }
    puts "seed #{options[:seed]}, #{options[:n]} rounds, 1 fresh process per trial", ""
    report(passed, arms, rng)
    check_digests(passed)
    check_failures(failed)
  ensure
    log&.close
    FileUtils.remove_entry(cwd_base) if cwd_base
  end
end

AB.main(ARGV) if $PROGRAM_NAME == __FILE__
