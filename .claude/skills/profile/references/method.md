# Method

These rules decide whether a number can be trusted. They apply to every stack.

## The box

Check before every timed run, and record the result beside the number:

```bash
cat /proc/loadavg
cat /proc/pressure/memory /proc/pressure/cpu
pgrep -af '[r]spec|[c]argo (test|build|bench)|[p]re-commit|[r]ustc' | head   # brackets keep it from matching itself
```

- A suite run, a compile, or a long background job on the same box makes the number
  useless. Wait, or say what was running.
- Run benches under `nice -n 10`, serially. If the repo has a bench or suite lock, take
  it (`flock`).
- Record what moves fork and memory numbers when those are the subject: transparent
  huge pages (`/sys/kernel/mm/transparent_hugepage/enabled`), the CPU governor, swap
  in use.
- A small sample swings with load. A 20-sample median went from 64 ms to 89 ms at load
  average 5.

## The evidence directory

Create it first, outside the scratch copy, and use its absolute path in every command.
Cleanup deletes the scratch copy; whatever was written inside it is lost.

```bash
evidence="$PWD/planning/<topic>-profiling-<YYYY-MM>"     # the directory beside the report
mkdir -p "$evidence"
```

The references write `evidence/<file>` for short. Read that as `"$evidence/<file>"`.
Raw `perf.data` files and heap dumps can be hundreds of MB. Keep the flamegraph and the
text summary, and delete the raw file unless the repo ignores it.

## The scratch copy

Profile a copy, so a debug build or a spike never touches the checkout. Pick by what the
workload needs:

| Workload | Copy |
|---|---|
| committed code, no repository state | `git archive HEAD \| tar -x -C "$scratch"` |
| uncommitted changes, or ignored files the app needs to boot | `rsync -a --exclude .git --exclude target --exclude tmp --exclude log ./ "$scratch/"` |
| real git state | `git worktree add --detach "$scratch" HEAD`, then copy the dirty and ignored files over |

```bash
scratch="${TMPDIR:-/tmp}/profile-<slug>"
mkdir -p "$scratch"
git status --porcelain          # anything listed is missing from a `git archive` copy
```

- `git archive` drops uncommitted work, which may hold the symptom, and every ignored
  file. A Rails app usually needs some of them to boot: `.env`, `config/master.key`,
  `config/database.yml`, `node_modules`. Run from the scratch copy with the same
  bundle (`BUNDLE_GEMFILE` unset, `bundle install` reuses the installed gems).
- **Give the copy its own database.** The copy reads the same `database.yml`, so a
  spec run that truncates, a `db:test:prepare`, or a spike that shares records across
  examples would act on the checkout's database. Set `DATABASE_URL` to a separate
  database (for example the test name with a `_profile` suffix) and load the schema
  there. The same goes for Redis, search indexes, and upload directories. If that
  cannot be done, say so and ask before running anything that writes.
- Copy built artifacts that take long to rebuild (a compiled extension, `target/`).
- A `git archive` copy has no `.git`. Code that walks the repository behaves
  differently there: 1 spec file took 6 s in such a copy and 109 s in the real
  checkout, because the subject listed every tracked file. Confirm the baseline matches
  the real tree before trusting the copy.
- Never copy a linked worktree with its `.git` pointer file in place. Git commands in
  the copy would act on the original.
- Use a `git worktree` when the workload needs real git state.

## The reproducer

A bench program is the workload, isolated and repeatable:

1. Build the state at the size that matters (10,000 turns, 500 files).
2. Warm up: run the measured call 3 times. In Ruby, `GC.start` after.
3. Time N repeats with a monotonic clock, in-process. Print the median as `ms=<n>`.
4. Print `digest=<hash of the result>`, so a faster arm that computes something else
   fails loudly.

Use absolute paths, so the working directory changes nothing.

**Ruby.** Keep setup in a shared file (`setup.rb`) and 1 small script per question:
`bench.rb` (wall), `phases.rb` (a lap timer around each step), 1 per profiler.

**Rust.** Put the same 4 steps in `examples/bench_<name>.rs` (or a `[[bin]]` in the
scratch copy), with `std::time::Instant` for the clock and `std::hint::black_box`
around inputs and results. Build once, then run the binary itself:
`target/release/examples/bench_<name>`. Never time `cargo run`, which checks the build
on every start. A criterion bench covers the in-process comparison; the example binary
is what `perf`, heaptrack, and the A/B run against.

**Rails.** A request or a job is the workload. Drive it in-process
(`ActionDispatch::Integration::Session` or the job's `perform`) in a script run with
`bin/rails runner`, in the environment whose settings match the symptom. Development
mode reloads code and skips caches, so its profile differs from production's.

In-process repeats steady 1 trial's number. The sample is the process: memory layout is
fixed at startup, so 300 repeats in 1 process is still 1 draw.

## Profilers disturb the run

- A probe that counts spawns, sleeps, and allocations raised system CPU 15% in 1
  measured run. Tracking every `malloc` slows allocation-heavy code about 6 times.
- `strace` slows every traced syscall evenly. Compare its rows, never its absolutes.
- Samplers miss samples in code they cannot interrupt. stackprof missed 35% in 1
  native-heavy run and under-counted the native frame. Cross-check with the phase timer.
- A timeout or watchdog that trips under a profiler is the profiler's doing.

## A/B rules

A result from 1 run is 1 sample. Before calling a change faster:

- **Fresh process per trial.** Layout, caches, and JIT state reset.
- **Interleave.** A B A B, order shuffled per round, so load drift lands on every arm.
- **Pad the environment.** Environment size moves stack alignment enough to reverse a
  difference of a few percent (Mytkowicz et al., "Producing Wrong Data Without Doing
  Anything Obviously Wrong!", ASPLOS 09). `scripts/ab.rb` sets a random `AB_PAD` of 0
  to 4,095 bytes per trial, which shifts the initial stack by up to a page.
- **Vary the working directory.** `scripts/ab.rb` also runs each trial in a directory
  whose path is 1 to 200 bytes longer than a temporary base, and removes it after. So
  write every arm with absolute paths. A `cd` inside an arm undoes this part; where a
  tool needs a project directory, name it another way (`BUNDLE_GEMFILE=/abs/Gemfile`,
  `cargo --manifest-path`). `--no-cwd-pad` turns it off for a workload that reads its
  working directory.
- **Fresh seed per experiment**, recorded. A reused shuffle seed gives every experiment
  the same order.
- **Same build for every arm** where possible: gate the spike on an environment
  variable. Otherwise record each tree's SHA.
- **n per arm:** 5 to see a 2x change, 20 as the floor for a change near 10%. n grows
  with the noise: at 10% noise, n = 20 finds a 10% change about 3 times in 4. A slow
  measure (a whole suite run) can use 8 when the expected change is large.
- **Report** the median, the spread, the ratio, and the interval. `scripts/ab.rb`
  prints a bootstrap 95% interval of the ratio of medians.
- **A gain must beat the layout.** For each arm `scripts/ab.rb` prints the pad spread:
  the trials are split into 4 buckets by pad size, and the spread is the largest
  bucket median minus the smallest. That is how far layout alone moved the arm. The
  verdicts:

  | Verdict | Meaning |
  |---|---|
  | `differs` | the interval excludes 1, and the shift in medians exceeds the larger arm's pad spread |
  | `within layout` | the interval excludes 1, but the shift is no larger than what the pad alone does. Do not claim the gain; raise n or call it unproven |
  | `not shown` | the interval includes 1. That is "inconclusive at this n", never "equal" |

  A bucket needs 3 trials to count, so the spread prints `-` below about n = 12 and
  the interval decides alone. That is fine for a 2x claim and too weak for a small one.
  The NDJSON from `--out` has `pad` and `cwd_len` per trial for a closer look.
- **Keep failed runs** in view, or name the exclusion rule. `scripts/ab.rb` records a
  failed or timed-out trial with `ok: false`, leaves it out of the medians, prints the
  count per arm, and exits 1. Pass `--timeout <seconds>` so a hung arm cannot hang
  the run.
- **Clean environment per arm.** `scripts/ab.rb` removes `BUNDLE_*`, `RUBYOPT`, and
  `RUBYLIB` from each trial, so an arm in another tree resolves its own Gemfile. An
  arm that needs one sets it in its own command (`RUBYOPT=--yjit ruby ...`).

```bash
ruby ~/.claude/skills/profile/scripts/ab.rb --n 20 --seed 7 --out trials.ndjson \
  base="BUNDLE_GEMFILE=$scratch/Gemfile bundle exec ruby $scratch/bench/bench.rb" \
  spike="SPIKE=1 BUNDLE_GEMFILE=$scratch/Gemfile bundle exec ruby $scratch/bench/bench.rb"
```

`hyperfine` is fine for whole-command wall time of 2 binaries. It runs each command's
trials in a block by default, so it does not replace an interleaved run for a small
effect. On a box with no Ruby, alternate the arms by hand in a shell loop and compare
medians.

## Reading results

- Rows of a cost table often overlap. Say so, and do not add them.
- Idle is not cost. A background thread parked on a queue for 300 s costs nothing.
  Split blocked time by thread, and count what the measured work waits on.
- Wall time across parallel workers is about `max(slowest unit, total work / workers)`.
  Know which term binds before choosing what to fix.
- A cost that shows in 1% of the units can be half the total. Sort and look at the
  top before averaging.
- Compare against "do nothing" at the size users reach. A 100 ms cost at 10,000 turns
  is 10 ms at 1,000.
- A gain can move cost elsewhere. Re-run the phase timer after the spike.

## Installing tools

Check with `command -v`. If a tool is missing, print the install command and ask. Never
install packages unprompted; `cargo install` and `gem install` outside the scratch copy
count.

**Root.** Never run `sudo`. A command marked "root" in a reference is one the user
runs: give them the full line as `! sudo <command>` and wait for the output file. This
covers `bpftrace`, the bcc tools (`offcputime`, `memleak`, `runqlat`, `execsnoop`),
and attaching to a process you did not start: with `kernel.yama.ptrace_scope` at 1,
`rbspy --pid` and `perf -p` reach only your own child processes. Start the target
under the profiler, or have the bench spawn the profiler on itself.

`perf` as a normal user needs `kernel.perf_event_paranoid` at 2 or lower for the user's
own processes, and 1 or lower for kernel frames.

The bcc tools matter by build. The libbpf builds (Arch `bcc-libbpf-tools`, Debian and
Ubuntu `libbpf-tools`) take options the Python `*-bpfcc` builds lack.

## macOS

The references assume Linux. On macOS:

| Linux | macOS |
|---|---|
| `/usr/bin/time -v` | `/usr/bin/time -l` |
| `perf record` | `samply record`, or `xcrun xctrace record --template "Time Profiler"` |
| `/proc/self/status` VmRSS | `ps -o rss= -p <pid>` |
| `strace` | `dtruss` (root, and limited by System Integrity Protection) |
| bcc tools, `bpftrace` | none; use `sample <pid>` for stacks of a waiting process |
| `malloc_trim` | none |

rbspy needs root there. stackprof, Vernier, memory_profiler, test-prof, criterion, dhat,
and `scripts/ab.rb` work unchanged.
