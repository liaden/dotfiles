# Ruby

Use the gems already in the bundle first. A profiler gem that is missing goes in the
scratch copy's Gemfile only. Check that it builds on the project's Ruby before planning
around it.

Figures marked "1 measurement" come from 1 project on 1 box. They show the scale a
cost can reach. They are never a threshold: measure the project in front of you.

Run a script without the `bundle exec` re-exec when a tool attaches by pid:
`ruby -rbundler/setup script.rb`. `bundle exec` replaces the process image, and a tracer
attached to the first image stops seeing the program. It also adds a second Ruby start
(0.14 s, 1 measurement).

## Lenses

| Lens | First tool | Others |
|---|---|---|
| cpu | stackprof `:cpu` | Vernier, `perf` for C frames |
| wall, off-CPU | stackprof `:wall`, Vernier `:wall` | rbspy, `offcputime`, `strace -c` |
| gvl | Vernier thread states, the ticker probe | gvltools, gvl-tracing |
| memory, allocations | memory_profiler, `GC.stat` deltas | Vernier allocations, `ObjectSpace.trace_object_allocations` |
| memory, retained | `ObjectSpace.dump_all` + sheap or heap-profiler | Vernier `:retained` |
| memory, RSS | VmRSS against `ObjectSpace.memsize_of_all` | `malloc_trim` test, bcc `memleak`, jemalloc build |
| gc | `GC.stat` deltas | `GC::Profiler`, GC frames in stackprof |
| spawn | `strace -f -c`, a `Process.spawn` hook | `execsnoop`, bpftrace |
| boot | `hyperfine`, stackprof `:wall` around `require` | bootsnap warm against cold |
| other processes | rbspy `--subprocesses` | |
| a test suite | test-prof: TagProf, RSpecDissect, EventProf, `TEST_STACK_PROF` | `rspec --profile` |
| factories | test-prof: FactoryProf (`FPROF`), FactoryDoctor (`FDOC`) | `FACTORY_DEFAULT_PROF` |

## CPU

```ruby
require "stackprof"
3.times { work }
GC.start
StackProf.run(mode: :cpu, interval: 200, raw: true, out: "evidence/sp-cpu.dump") do
  300.times { work }
end
```

```bash
stackprof evidence/sp-cpu.dump --text --limit 20             # by self
stackprof evidence/sp-cpu.dump --text --sort-total --limit 20
stackprof evidence/sp-cpu.dump --method 'Canonical.normalize'  # callers and callees
stackprof evidence/sp-cpu.dump --stackcollapse | inferno-flamegraph > evidence/ruby-cpu.svg
```

- `interval` is microseconds in cpu and wall mode. 200 to 1,000 is the usual range.
- `raw: true` is needed for flamegraphs.
- `(garbage collection)`, `(marking)`, and `(sweeping)` frames are GC share. Over 10%
  sends you to the gc and allocation lenses.
- A C or Rust extension method shows as 1 frame with no inside. For its inside use
  `perf` (see `ruby-rust.md`).
- Without YJIT, `perf` shows Ruby code as `vm_exec_core`. Read stackprof for Ruby
  frames.
- With no code change: `stackprof run --mode=cpu --raw --out="$evidence/sp.dump" -- ruby script.rb`
  profiles a whole command, boot included. Without `--raw`, `--stackcollapse` prints
  nothing.
- The command line labels `--interval` in milliseconds while the API's `interval:` is
  microseconds. Leave the command line's at its default.

Vernier (Ruby 3.2.1+) gives the same view per thread, with GC pauses and GVL state on a
timeline:

```bash
vernier run --output evidence/vernier.json -- ruby -rbundler/setup script.rb
```

```ruby
Vernier.profile(out: "evidence/vernier.json") { work }          # wall is the default mode
```

The JSON opens in the Firefox Profiler (https://vernier.prof, loaded locally in the
browser). The user reads that; for the report, take the top frames from stackprof or
from `vernier view` where the installed version has it.

## Wall and off-CPU

Use this when wall is well above CPU.

```ruby
StackProf.run(mode: :wall, interval: 1000, raw: true, out: "evidence/sp-wall.dump") { work }
```

- Wall mode samples a thread whether it runs or waits. Frames such as `IO.select`,
  `Queue#pop`, `sleep`, `Process.wait`, and `Mutex#synchronize` are waits.
- Sort waits by thread before counting them. A reader thread parked on `Queue#pop` is
  idle. Ruby's `Timeout` keeps 1 background thread per process that parks in
  `timeout.rb`; it is idle too. Only waits on the measured work's own thread or fiber
  are cost.
- Fixed sleeps, poll intervals, and timeouts waited out in full are the usual finds:
  a monitor that polls every 1.0 s and is joined without a wake-up costs up to 1 s per
  call. grep for `sleep`, `timeout:`, and `TICK` on the path.
- `rbspy` samples from outside, with no change to the program, and follows children:

  ```bash
  rbspy record --rate 50 --subprocesses --format flamegraph --file evidence/rbspy.svg -- <command>
  rbspy record --pid <pid> --duration 30 --format collapsed --file evidence/rbspy.txt
  ```

  The first form needs no root, because the target is rbspy's child. The `--pid` form
  on a process started elsewhere needs root on most Linux boxes
  (`kernel.yama.ptrace_scope` at 1) and always on macOS: the user runs it.

  It shows what in-process profilers cannot: child Ruby processes booting. Add
  `--nonblocking` if pausing the target changes its behavior, at the price of some
  torn stacks.
- Syscall view, no root: `strace -f -c -o evidence/strace.txt <command>` for counts and
  time per syscall, `strace -f -T -e trace=<set>` for single slow calls.
- Kernel view, root, run by the user: `offcputime -p <pid> -f 30 > off.txt`, then
  `inferno-flamegraph --colors io < off.txt`. Ruby has no frame pointers by default, so
  user frames above the first are unreliable.

## GVL

1 Ruby thread runs Ruby code at a time. The GVL is released during blocking I/O,
`sleep`, and C calls that opt in. 3 different questions hide under "GVL":

**How long did threads wait for the GVL?**

```ruby
require "gvltools"
GVLTools::GlobalTimer.enable
before = GVLTools::GlobalTimer.monotonic_time
work
waited_ms = (GVLTools::GlobalTimer.monotonic_time - before) / 1e6   # all threads, summed
```

`GVLTools::LocalTimer` gives the same per thread, and `GVLTools::WaitingThreads.count`
the queue length. A GVL wait of 3% of total work is not the problem.

**Who held it?** Vernier's timeline marks each thread running, stalled (wants the GVL),
or suspended (blocked, GVL released). A thread stalled while another runs 1 long frame
names the holder. gvl-tracing writes the same picture for Perfetto:

```ruby
require "gvl-tracing"
GvlTracing.start("evidence/gvl.json") { work }
```

**Does 1 call starve another thread?** The ticker probe measures it directly. Run the
suspect work on a thread and measure the gap between 1 ms sleeps on the main thread:

```ruby
CLOCK = -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
def ticker(work)
  gaps = []
  done = false
  thread = Thread.new { work.call; done = true }
  last = CLOCK.()
  until done
    sleep 0.001
    now = CLOCK.()
    gaps << (now - last) * 1000
    last = now
  end
  thread.join
  gaps.sort
end
idle = ticker(-> { sleep 0.5 })
busy = ticker(-> { suspect_work })
printf "idle p50 %.2f max %.2f | busy p50 %.2f p99 %.2f max %.2f ms\n",
       idle[idle.size / 2], idle[-1], busy[busy.size / 2], busy[(busy.size * 0.99).floor], busy[-1]
```

The idle run is the floor (a 1 ms sleep takes a little over 1 ms). A p99 of 25 ms
against that floor means the work held the GVL for 25 ms stretches, and the UI, the stream reader, and every fiber on the main thread waited.

- Pure-Ruby CPU work on a background thread still takes the GVL in 100 ms time slices.
  A thread does not make it parallel.
- To prove a C call releases the GVL, count increments on a second thread during 1
  call: 0 means held.
- Fibers under a scheduler share 1 thread. A blocking call in a fiber holds the whole
  reactor unless the scheduler offloads it; check whether the scheduler has a worker
  pool and whether it is enabled.
- A quadratic method on 1 thread shows up as GVL wait on every other thread. Fix the
  method.

## Memory

Decide which number is wrong first: allocations per call (GC pressure, time), retained
objects (a leak), or RSS (the process size).

**Allocations.**

```ruby
before = GC.stat(:total_allocated_objects)
work
puts GC.stat(:total_allocated_objects) - before
```

That count is free and exact. For the call sites:

```ruby
require "memory_profiler"
MemoryProfiler.report { work }.pretty_print(to_file: "evidence/alloc.txt", scale_bytes: true)
```

memory_profiler lists allocated and retained memory by gem, file, location, and class.
It slows the block many times over, so give it 1 call at a small size. For a large
workload, sample 1 allocation in 100 with `Vernier.profile(out:, allocation_interval: 100)`.
`Vernier.profile(mode: :retained, out:)` records only the allocations still live at the
end of the block.

Allocation counts mislead about time. A million objects cost 32 ms of GC in 1 measurement. Check the
gc lens before spending effort here.

**Retained objects.** Take 2 or 3 heap dumps across repeats of the workload and diff
them. Growth between the second and third dump is the leak; the first holds warm-up.

```ruby
require "objspace"
ObjectSpace.trace_object_allocations_start      # records file:line per object; slow
work; GC.start
File.open("evidence/heap-1.json", "w") { ObjectSpace.dump_all(output: _1) }
```

Diff them with sheap as a library (its command line opens IRB, which an agent cannot
drive), or with `heap-profiler`:

```ruby
require "sheap"
diff = Sheap::Diff.new("evidence/heap-2.json", "evidence/heap-3.json")
pp diff.retained.map(&:type_str).tally.sort_by(&:last).last(15)
```

Usual causes: an identity-keyed Hash used as a memo, a registry that never removes entries,
a closure holding a large receiver. `ObjectSpace::WeakMap` holds keys and values
weakly, so an entry can vanish while its key lives; that costs a miss.

**RSS.** RSS is often far above live Ruby objects, and the gap has 3 owners:

```ruby
require "objspace"
GC.start(full_mark: true, immediate_sweep: true)
rss_kb = File.read("/proc/self/status")[/VmRSS:\s+(\d+)/, 1].to_i
puts "rss #{rss_kb / 1024} MB, ruby objects #{ObjectSpace.memsize_of_all / 1_048_576} MB, " \
     "pages #{GC.stat(:heap_allocated_pages)}, live slots #{GC.stat(:heap_live_slots)}"
```

1. Memory glibc freed and kept. Test it:

   ```ruby
   require "fiddle"
   Fiddle::Function.new(Fiddle.dlopen(nil)["malloc_trim"], [Fiddle::TYPE_INT], Fiddle::TYPE_INT).call(0)
   ```

   Read VmRSS again. In 1 measured worker this returned 100 MB of 345 MB.
2. Ruby's own `xmalloc` outside object slots, which `memsize_of_all` under-counts (by
   half in 1 measurement).
3. Native libraries. bcc `memleak` attributes outstanding `malloc` bytes to the calling
   library (see `ruby-rust.md` for the recipe and its traps).

- The boot is usually the largest single allocation event: `require` of a big library
  allocates heavily (700,000 objects in 1 measurement), paid once per process and
  visible as RSS.
- An allocator test needs a Ruby built with jemalloc from the same source as the
  control. `LD_PRELOAD` puts jemalloc into every child process too, so the comparison
  measures something else.
- `MALLOC_ARENA_MAX=2` and trim thresholds are cheap to try and need an RSS
  measurement, since time rarely moves.
- Peak RSS for a whole command: `/usr/bin/time -v`, "Maximum resident set size".

## GC

```ruby
def gc_delta
  before = GC.stat
  yield
  after = GC.stat
  %i[count minor_gc_count major_gc_count time total_allocated_objects].to_h { [_1, after[_1] - before[_1]] }
end
```

- `time` is milliseconds of GC. Divide by the wall of the block: under 5% means GC is
  not the lever.
- Many major GCs point at old-object growth or `malloc` limits (`oldmalloc_increase_bytes`
  against its limit). Many minor GCs point at allocation rate.
- `GC.stat_heap` gives the same per slot size, to see which size class churns.
- `GC::Profiler.enable; work; GC::Profiler.report` lists each collection with its time.
- More live objects make every major mark slower. A cache that doubles the object count
  can cost more in marking than it saves.
- Tuning comes last, after the allocation fix, as an A/B with RSS recorded:
  `RUBY_GC_HEAP_0_INIT_SLOTS` to presize (cuts boot GCs in short-lived children),
  `RUBY_GC_HEAP_GROWTH_FACTOR`, `RUBY_GC_MALLOC_LIMIT`, `RUBY_GC_OLDMALLOC_LIMIT`.
- `GC.compact` before a fork measured slower, with no RSS change.

## Spawns

Shelling out from a large Ruby process is often dearer than the program it runs.

```bash
strace -f -c -e trace=process -o evidence/spawn.txt <command>    # clone, vfork, execve, wait4 counts and time
```

- `fork` copies page tables, so its cost grows with the parent's RSS: 7.7 ms at 98 MB
  and 29.4 ms at 371 MB for 1 `git rev-parse`, against 1.3 ms flat for `Process.spawn`
  (vfork), in 1 measurement. Libraries that fork before exec pay this on every call.
- A forked child pays again at `execve`, tearing down the copied address space.
- Count spawns per call site with a hook on `Process.spawn` that records `caller_locations`
  to the nearest project frame. 11 `git` runs per operation is a finding.
- A fixture built per example and a subject that spawns per item both show here. Say
  which one owns the spawns.
- Root, whole system, run by the user: `execsnoop`, or bpftrace on `sched_process_exec`.

## Boot

```bash
hyperfine --warmup 3 'ruby -rbundler/setup -e "require %q(mylib)"' 'bundle exec ruby -e "require %q(mylib)"'
```

- Profile the require: `StackProf.run(mode: :wall, ...) { require "mylib" }` in a fresh
  process.
- bootsnap: measure warm, cold, and absent. A cold cache is slower than none (1.24 s
  cold, 0.92 s none, 0.44 s warm in 1 measurement), so a fresh cache per process loses.
- bootsnap keys on mtime in seconds and size. 2 same-size edits in 1 second run stale
  bytecode. Disable it in any run that rewrites source files.
- Version-manager shims add a process start each (135 ms per editor boot in 1
  measurement). Resolve the real binary.
- Count child boots when a test suite is the subject. No in-process profiler shows
  them (320 boots at about 1 s each in 1 measured suite).

## Test suites

test-prof is the first tool when the subject is a suite. Every profiler is switched on
by an environment variable, so nothing in the specs changes. It needs
`require "test_prof"` (or the recipe files) loaded from the spec helper.

Go from general to specific. Each step picks the next:

| Step | Command | Answers |
|---|---|---|
| 1 | `rspec --profile 20` | which examples and groups are slow. 1% of examples can be half the work |
| 2 | `TAG_PROF=type rspec` | time and example count per spec type (or any tag) |
| 3 | `RD_PROF=1 rspec` | how much of the time is `before` hooks and `let`, and which groups spend it |
| 4 | `EVENT_PROF=factory.create rspec` | the groups that spend most time in an event. Also `sql.active_record`, any `ActiveSupport::Notifications` event |
| 5 | `TAG_PROF=type TAG_PROF_EVENT=sql.active_record,factory.create rspec` | share of each event per spec type |
| 6 | `TEST_STACK_PROF=1 rspec` | a stackprof of the run. `TEST_STACK_PROF=boot` for load time, `TEST_STACK_PROF_MODE=wall` for waits, `TEST_VERNIER=1` for Vernier |
| 7 | `TEST_MEM_PROF=rss rspec` (or `alloc`) | the examples and groups that grow memory most |

`SAMPLE=200 rspec` runs a random 200 examples, and `SAMPLE_GROUPS=20` a random 20
groups. Use a sample for steps 2 to 5 on a large suite; shares hold, totals do not.

### Factories

In a Rails suite with FactoryBot (or Fabrication), factories are a usual suspect, and
`EVENT_PROF=factory.create` gives their share for this suite. This section is general
knowledge with no measured run behind it yet. A factory with associations creates a cascade, so 1 `create(:comment)` can insert a
post, a user, and an account.

| Command | Answers |
|---|---|
| `FPROF=1 rspec` | per factory: total count, top-level count, total time, time per call. A total far above top-level means the factory is mostly created as someone's association |
| `FPROF=flamegraph rspec` | the factory stacks as an HTML flamegraph: which top-level factory pulls in which cascade |
| `FPROF=1 FPROF_VARS=1 rspec` | the same, split by trait and override combination |
| `FPROF=json rspec` | the simple report as a file, for the evidence directory |
| `FDOC=1 rspec` | FactoryDoctor: examples that create records and never touch the database, with the time wasted. Candidates for `build_stubbed` |
| `FACTORY_DEFAULT_PROF=1 rspec` | which associations are created most often, the candidates for a shared default |

Read FactoryProf with RSpecDissect beside it. Records created in `let` and `before`
are re-created per example, and that pair of reports says which groups do it.

The fixes, cheapest first. Each is a candidate to measure, per file, with the example
count checked before and after:

1. `build_stubbed` or `build` where FactoryDoctor says the database is not needed.
2. Remove associations a factory does not need by default; move them to traits.
3. `let_it_be` and `before_all`: create once per group inside a transaction. A record
   shared across examples can leak state, so use `reload: true` or `refind: true`
   where an example mutates it. FactoryDoctor and `RD_PROF` name the groups.
4. `create_default` (FactoryDefault): reuse 1 record for a repeated association, such
   as the account every record belongs to.
5. AnyFixture: build expensive shared data once per run. `ANYFIXTURE_REPORT=1` shows
   what each fixture cost and saved.

Limits:

- `let_it_be`, `before_all`, and FactoryDefault rest on database transactions. In a
  suite with no database they do not apply; the same idea there is build the fixture
  once per process and copy it (a git repository built in 27 ms copied in 3.5 ms, 1 measurement).
- Under a parallel runner each worker writes its own report, and file-based outputs
  overwrite each other. Suffix dumps per worker (a `RUBYOPT` preload keyed on
  `TEST_ENV_NUMBER`), or profile serially on a sample.
- A profiled suite run is slower, and timing-sensitive examples can fail under it.
  That failure belongs to the profiler.
- Split every slow file's cost between the fixture and the subject before changing
  it. A cost in the subject is an application finding, and a faster fixture hides it.

## YJIT

```bash
RUBYOPT=--yjit <command>
```

- Measure it as a whole-app A/B with peak RSS. Hot pure-Ruby loops gained 35% in 1
  measured render; a subprocess-bound test suite gained nothing and RSS rose 13%.
- Short-lived children can get slower with YJIT on (1.08 s boot against 0.88 s, 1
  measurement).
- `RubyVM::YJIT.runtime_stats` shows compiled size and side exits. `--yjit-perf` writes
  a perf map so `perf` names JIT frames.
- Profile with the same YJIT setting production uses. The hot list changes.

## Traps

- `Benchmark.realtime` on 1 call measures warm-up and GC luck. Use the median of many.
- `benchmark-ips` compares 2 implementations in 1 process. That is right for a micro
  choice and wrong for layout-sensitive claims; follow with `scripts/ab.rb`.
- A time asserted in a spec is a flake. Keep timings in a bench script with a ceiling
  checked on demand.
- A profiler loaded through `RUBYOPT` reaches child Ruby processes, and each child then
  writes the same dump file. Suffix the output per process (`Process.pid`).
- An identity memo needs stable object identity upstream. If each call builds fresh
  objects, the memo never hits; count hits before timing.
- Re-normalizing data that is already normal can cost almost as much as the first time
  (88% in 1 measurement). Mark normal data and skip it.
