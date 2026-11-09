---
name: profile
description: Profile a Ruby, Rust, or Ruby+Rust (native extension) program and report where the cost is. Covers CPU, wall and off-CPU time, GVL contention, memory and allocations, GC, process spawns, boot time, and test suites (test-prof, FactoryBot factory usage). Use when asked to profile, find a hot path or a slowdown, explain memory growth or a stall, or check that a change is faster.
argument-hint: <command, spec file, or symptom> [cpu|wall|gvl|memory|gc|spawn|boot|suite|factories]
---

# profile

The output is a report: where the cost is, how it was measured, and what to change,
ranked. Change no production code. A fix is tried as a spike in a scratch copy, and the
report carries the diff.

A profile gives shares. A timed A/B gives the size of a gain. The report needs both, and
it marks every number as 1 of 4 kinds:

| Status | Meaning |
|---|---|
| measured | a timed run or a kernel counter |
| reproduced | measured by 2 independent methods |
| read | arithmetic from code and profile data |
| estimated | a guess with a stated basis |

## Inputs

| File | Holds |
|---|---|
| `references/method.md` | the quiet box, the scratch copy, the reproducer, the A/B rules. Read it every time. |
| `references/ruby.md` | Ruby lenses, tools, and traps |
| `references/rust.md` | Rust lenses, tools, and traps |
| `references/ruby-rust.md` | native extensions: which side owns the cost, the boundary, the GVL, memory on both heaps. Read `ruby.md` and `rust.md` first. |
| `references/report-template.md` | the report |
| `scripts/ab.rb` | interleaved A/B, 1 fresh process per trial |

The repo's own tools win. Before choosing a tool from the references, read the repo's
`CLAUDE.md` and look for `bin/*prof*`, `bin/*bench*`, `bin/*trace*`, a `benches/`
directory, and a performance doc. If the repo already has a lens for the question, use
it and say so.

## 1. Pin the question

A profiling round answers 1 question about 1 workload. Settle these from the request and
the code, and ask the user only for what neither answers:

- The workload: a command that shows the symptom. "The app is slow" has no profile.
- The metric: wall, CPU, p99 latency, peak RSS, allocations per call, stall on another
  thread.
- The size that matters: 100 turns or 10,000, 1 file or 500. A cost that scales shows
  only at the right size.
- Who pays: every user per call, a developer per suite run, CI per job.

Detect the stack: `Gemfile` or `*.gemspec`, `Cargo.toml`, and for a native extension
`ext/*/Cargo.toml` naming `magnus` or `rb-sys`. Read the matching references.

## 2. Find prior work

Glob `*profil*`, `*perf*`, and `*research*` under `planning/` and `docs/`, and search
mempalace (`~/.claude/reference/mempalace.md`). An earlier report often names the
workload, the baseline, and the lenses that showed nothing. List what exists with dates.
Reuse its bench scripts when they still run.

## 3. Build the reproducer and the baseline

Follow `references/method.md`, in this order: the evidence directory (an absolute path
beside the report, outside the scratch copy), the scratch copy with its own database
where the app has one, the bench program that prints `ms=` and `digest=`, the quiet-box
check, then a baseline of at least 3 runs with the load average beside each.

Confirm the scratch copy shows the symptom at the size the user sees. If it does not,
the difference between the copy and the real tree is the first finding.

## 4. Split the time before sampling it

Run the cheapest split first. It picks the lens and saves a wrong profile.

```bash
/usr/bin/time -v <command>        # wall, user, sys, peak RSS, context switches
```

`time` adds the children's CPU into user and sys. To separate them, read
`Process.times` at the end of a Ruby script (`utime` and `stime` against `cutime` and
`cstime`), or `getrusage(RUSAGE_CHILDREN)` in Rust.

| What the split shows | Lens |
|---|---|
| user CPU near wall | cpu |
| wall well above user + sys | wall (off-CPU): sleeps, I/O, locks, child processes |
| sys CPU high | spawn (fork, exec), page faults, syscalls |
| several busy Ruby threads, user CPU still about equal to wall | gvl: the threads take turns |
| Rust threads, CPU well under threads x wall, sys CPU or `futex` high | lock contention |
| 1 thread's work delays another thread | gvl (Ruby), lock contention (Rust) |
| peak RSS high or growing | memory |
| many short pauses, or allocation frames in the cpu profile | gc, then memory (allocations) |
| slow before the first line of work | boot |
| children's CPU (`cutime` + `cstime`) above the parent's | spawn and boot, in the children |

Then time the phases of the hot call by hand (a monotonic clock around each step, median
of 30 or more). A sampler drops samples while native code runs with signals deferred,
so it under-counts those frames; the phase timer is the number to trust for how the time
divides.

## 5. Profile through 1 lens at a time

Pick the tool for the lens from the stack's reference. For each run record the command,
the tool version, the sampling rate, and the load average.

- Warm up before the profiler starts, and attach after setup, so the profile holds the
  workload and nothing else.
- A profiled run is slower. Use it for shares, never for wall time.
- Save the raw dump and a flamegraph SVG into `"$evidence"`, by absolute path.
- Read self time to find the frame doing the work, and total time to find the caller to
  change.
- State the top 10 frames, by self and by total, as a table in the report.

Stop adding lenses when the question is answered. A lens that showed nothing goes in the
report in 1 line, with its number, so nobody repeats it.

## 6. Explain the cost

A hot frame is where the cost shows. The finding is why the frame runs that often or
that long: called per item where once would do, rebuilding something that did not
change, copying across a boundary, holding a lock during work that needs none. Read the
code on the path and say it in 1 or 2 sentences, with `path:line`.

Split the cost by owner. A cost in a test fixture is a spec finding. A cost inside the
subject is an application finding, and it helps every user.

## 7. Spike and measure each candidate

For each candidate fix, in the scratch copy:

1. Write the smallest change that tests the idea. Gate it on an environment variable so
   1 build serves every arm.
2. Check correctness first: every arm prints the same `digest=`.
3. Compare with `scripts/ab.rb`, baseline first:

   ```bash
   ruby ~/.claude/skills/profile/scripts/ab.rb --n 20 --timeout 120 --out "$evidence/ab-<candidate>.ndjson" \
     base="BUNDLE_GEMFILE=$scratch/Gemfile bundle exec ruby $scratch/bench/turn.rb" \
     spike="SPIKE=1 BUNDLE_GEMFILE=$scratch/Gemfile bundle exec ruby $scratch/bench/turn.rb"
   ```

   Each trial runs in a fresh process with a random environment size and a random
   working-directory length, so the arms use absolute paths and no `cd`. Report the
   verdict as printed: `differs`, `within layout` (the gain is no larger than what
   memory layout alone moves the arm), or `not shown`.

   For Rust the arms are 2 built binaries, or 1 binary with the spike behind an
   environment variable:

   ```bash
   ruby ~/.claude/skills/profile/scripts/ab.rb --n 20 --timeout 120 --out "$evidence/ab-<candidate>.ndjson" \
     base="$scratch/target/release/examples/bench_turn" spike="SPIKE=1 $scratch/target/release/examples/bench_turn"
   ```

4. Re-run the phase timer on the winner, so the report says which phase shrank and which
   grew.

For a larger spike, spawn the `spike` agent with the question, the bench command, and an
absolute path to a throwaway worktree. Keep each spike as a diff in the evidence
directory.

Report rejected candidates with their numbers. "Measured, no change" is a result.

## 8. Write

Read `~/.claude/reference/writing-style.md`. Fill `references/report-template.md`. Save
as `planning/<topic>-profiling-<YYYY-MM>.md`, beside the evidence directory of the same
name. If the repo has no `planning/`, ask for a location in step 3, before the first
file is written.

Before cleanup, copy the bench scripts and each spike diff from the scratch copy into
`"$evidence"`, and `ls "$evidence"` to confirm every file the report names is there.
Then remove the scratch copy, any worktree, and any database created for the copy. Confirm `git status` and `git worktree list`
match the start.

Reply with the top finding and its measured gain in under 5 lines, the open questions,
the report path, and the friction log path with its entry count. The fix itself goes
through `/create-plan`.

## Friction log

File: `~/.claude/friction/<repo>-<YYYY-MM-DD>-profile-<slug>.md`, 1 per round. Start it
in step 1. Only the main session writes, by shell append. Never read it during a round.

```bash
echo "$(date +%FT%H:%M) | profile | step 5 | ref-wrong | memory | heaptrack_print -F wrote no stacks on 1.5 | 2 reruns | rust.md should name the flag per version" >> ~/.claude/friction/<file>
```

Fields: time, skill, step, kind, lens, what happened, cost, suggested fix.

Kinds:

| Kind | When |
|---|---|
| `ref-wrong` | a command, flag, or API in a reference failed or behaved differently |
| `skill-gap` | a step did not say what to do, or no lens fit the symptom |
| `tool` | a tool was missing, would not build on this Ruby or rustc, or needed root |
| `env` | a noisy box, a lock, a scratch copy that behaved unlike the real tree |
| `wrong-lens` | a profile that answered nothing, and what would have picked the right lens sooner |
| `misleading` | a number that looked like a finding and was not (a missed-sample profile, an idle wait counted as cost, a 1-sample gain) |
| `permission` | a blocked command |
| `worked` | a rule that stopped a wrong conclusion |

Write an entry on: a question sent to the user, a retry, a command that had to be
changed from what a reference says, a tool installed or swapped, a profile thrown away,
or any step where this skill did not say what to do. Record the tool version in the
entry when a tool is involved. Keep all notes on the skill here, never in the report or
a scratch file.

At close-out, write 1 `worked` entry for each rule that stopped a wrong conclusion,
with the evidence. These mark what a later simplification must keep.

Never edit the skill during a round. To use the log later, run
`/critique ~/.claude/friction` and ask for skill edits.
