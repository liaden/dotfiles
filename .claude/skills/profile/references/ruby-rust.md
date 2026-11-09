# Ruby + Rust (native extension)

For a gem with a Rust extension (magnus, rb-sys). Each profiler sees 1 side:

| Tool | Ruby frames | Rust frames |
|---|---|---|
| stackprof, Vernier, rbspy | yes | the binding shows as 1 method with no inside |
| `perf` | `vm_exec_core` and `vm_call_cfunc*` without YJIT | yes, with symbols |

Figures marked "1 measurement" come from 1 project on 1 box. They show the scale a
cost can reach. They are never a threshold: measure the project in front of you.

So the work has 4 steps: find which side owns the cost, profile that side with its own
tool, look at the boundary, then the GVL.

## The extension build

Build the extension with symbols in the scratch copy only:

```bash
CARGO_PROFILE_RELEASE_DEBUG=true CARGO_PROFILE_RELEASE_STRIP=false bundle exec rake compile
file lib/<gem>/<gem>.so      # "with debug_info, not stripped"
```

Check which `.so` the process loads (`$LOADED_FEATURES.grep(/\.so/)`). A bench that
loads the installed gem's extension profiles the wrong build.

## 1. Which side owns the cost

Attach `perf` from inside the bench after setup and warm-up, so the profile holds only
the workload:

```ruby
require_relative "setup"
3.times { work }
out = "evidence/perf.data"
perf = spawn("perf", "record", "-F", "999", "--call-graph", "dwarf,32768", "-o", out, "-p", Process.pid.to_s,
             out: File::NULL, err: File::NULL)
begin
  sleep 1.5
  Integer(ENV.fetch("REPS", "100")).times { work }
ensure
  Process.kill("INT", perf)
  Process.wait(perf)
end
```

`perf` is the bench's own child here, so no root is needed. The `ensure` stops it when
the workload raises; a stray `perf record` keeps writing until the disk fills.

```bash
perf report -i evidence/perf.data --no-children --sort dso --stdio | head -20
```

The split by library is the first number in the report: `libruby` (or `ruby`) is the
interpreter and Ruby code, the extension `.so` is Rust, `libc` is `malloc` and `memcpy`
for both, and other `.so` files are C extensions such as the JSON generator.

1 measured example: a cold render was 65% Ruby, 21% extension, 8% libc, 6% JSON. The
same render after 1 new turn was 82% Ruby and 3% extension. The Rust was fine, and Ruby
was re-processing what Rust had built.

Then:

- Mostly Ruby: stackprof, per `ruby.md`. The extension's methods appear as frames, so
  the profile also shows how often Ruby calls in.
- Mostly the extension: `perf report --sort symbol --dsos <ext>.so`, and the flamegraph,
  per `rust.md`.
- Thread names help. `perf report --sort comm` separated 97% of a run into 1 named
  background thread.

## 2. The boundary

Crossing costs little. Building Ruby objects costs a lot. In 1 measured binding the Rust
walk over 10,000 nodes took 1.7 ms and creating the 10,000 Ruby messages took 16 ms.

Measure these, in order:

1. **Calls per operation.** Count binding calls for 1 unit of work (the stackprof
   sample count for the method, or a counter). A binding called per item wants a batch
   form, 1 crossing per source.
2. **Objects built per call.** `GC.stat(:total_allocated_objects)` around the call.
   Every Hash, Array, and String the binding returns is allocated, marked by GC, and
   often frozen.
3. **What Ruby does next with the result.** The usual waste is after the call: Ruby
   normalizing, validating, re-sorting, or copying a value Rust already built in final
   form. Fixing that took a render from 37 ms to 14 ms; the Rust side changed by 10
   lines (insert keys in the order Ruby wants, mark the value as already normal).
4. **Copies in.** Converting a large Ruby value into Rust types can cost more than
   doing the job in Ruby's C code: a Rust digest over a copied payload took 26.9 ms
   against 7.1 ms for Ruby's own. Pass bytes (a String), or keep the data on the Rust
   side.
5. **Double work on both sides.** Hashing the same blob in Ruby and again in Rust cost
   0.23 ms per MB against 0.025 ms for the copy.

Things that measured as noise, so check before spending effort:

- Unprotected FFI calls in place of magnus's `rb_protect` wrappers: 23.7 ms to 23.1 ms.
- 1 batched callback in place of 10,000 funcalls back into Ruby: no change.
- A faster hasher on a map whose walk is pointer chasing: no change.

Per-thread caches (a compiled pattern or query cache in a `thread_local!`) are cold on
every new thread. If the app runs each call on a fresh thread, bench it that way.

## 3. The GVL

Every binding holds the GVL for its whole call unless it calls `rb_nogvl` or
`rb_thread_call_without_gvl`. grep the extension for both. Moving the call to a Ruby
thread changes nothing while it holds the GVL: the main thread still stops.

Measure with the ticker probe from `ruby.md`. 1 measured search over 500 files stalled
the main thread 25 ms at p99; releasing the GVL brought it to 1.09 ms, the idle
floor.

A GVL-release candidate needs 5 measurements, each an A/B against the current binding:

| Measure | What it shows |
|---|---|
| ticker p99 on the main thread during the call | the gain |
| per-call time on a typical input | the price where it matters |
| per-call time on a tiny input | the fixed price of releasing |
| time from `Thread#kill` to the join returning | whether cancel works |
| a second thread's counter during 1 call | proof the GVL is released at all |

Releasing the GVL buys responsiveness. It does not make the call faster, and it makes
Ruby threads parallel only inside the released region.

Hazards to test in the spike, each of which was found the hard way:

- **Panics.** A panic that unwinds through the `extern "C"` callback aborts the VM.
  The released region needs `catch_unwind`, and a spec that a panic raises a Ruby
  error and leaves the VM alive. The default panic hook still prints to stderr.
- **Interrupts.** `Thread#kill`, `Thread#raise`, and a fiber scheduler's stop reach a
  thread inside the region only through an unblocking function. With none, they land
  when the call returns.
- **Cancel points.** A cancel flag helps only where the code checks it. If 820 ms of a
  932 ms call is 1 parse, a check between results cancels nothing. Find a progress
  callback inside the long step.
- **No Ruby inside the region.** Copy every argument out of Ruby objects before
  releasing, build Ruby objects after. Another thread can mutate a String during the
  call.
- **Fiber schedulers.** `RB_NOGVL_OFFLOAD_SAFE` only helps when the scheduler
  implements `blocking_operation_wait` and its worker pool is on. Check both.
- **Unsafe.** Check whether the binding crate wraps a GVL release safely (magnus 0.9
  does not). Count the `unsafe`
  blocks the candidate adds, and read the extension's rules on new unsafe first.

## 4. Memory on 2 heaps

Ruby's tools see Ruby's heap. Rust allocations are invisible to `ObjectSpace` and
`memory_profiler`, and by default Ruby's GC does not know a small wrapper object pins
megabytes of Rust memory.

First split RSS (the snippet in `ruby.md`): VmRSS, `ObjectSpace.memsize_of_all`, and
what `malloc_trim(0)` returns. What remains is native: Ruby's own `xmalloc`, the
extension, other C libraries.

Then attribute the native part by library with bcc `memleak`. It needs root, so the
user runs it (`! sudo memleak ...`) against a pid the bench prints and holds:

```bash
memleak -p <pid> -T 200 --perf-max-stack-depth=1 --stack-storage-size=262144 15 > evidence/memleak.txt
```

Group each outstanding stack by its first frame outside libc: `libruby` is Ruby's
`xmalloc`, the extension `.so` is Rust. 3 traps:

- `bundle exec` re-execs on the same pid and the tracer loses the program. Start the
  target as `ruby -rbundler/setup -S <command>`.
- Ruby has no frame pointers, so frames past `malloc`'s caller are garbage and the
  stack table overflows. Record 1 frame.
- Stacks are symbolized while the process lives. Hold the process at exit (an
  `at_exit` that waits for a file) until the last snapshot is taken.

`heaptrack ruby -rbundler/setup script.rb` needs no root and unwinds with debug info,
so it gives deeper Rust stacks when the extension was built with symbols.

In 1 measured suite the extension held almost nothing outstanding and Ruby's `xmalloc`
held 74 MB. Measure before blaming the Rust heap.

Things to check when Rust does hold the memory:

- A cache or memo on the Rust side that never shrinks. Report its size at the end of
  the workload and what bounds it.
- A wrapped object without a size function. With magnus, implement
  `DataTypeFunctions::size` so `ObjectSpace.memsize_of` and the GC see it.
- A memo keyed by Ruby object identity, living in Rust, that pins a Ruby value per
  entry.

More Ruby objects returned from Rust means more GC marking. Adopting 10,000 more objects
into a `WeakMap` saved 22 ms of normalizing and added 6 ms to building them. Re-run the
phase timer after any change that alters object counts.

## 5. GC and wrapped objects

- A wrapped Rust struct that holds Ruby values needs a mark function, and no Rust-owned
  lock or borrow may be live across a call that can run Ruby (a GC, a funcall, a
  fiber switch).
- Specs that call `GC.start` or `GC.stress` on purpose dominate a GC-by-file table.
  Exclude them before reading it.
- `GC.compact` moves objects. A binding that stores a raw `VALUE` without marking it
  breaks there; that is a correctness finding to report, outside the performance
  question.

## Correctness guard

Every arm of every comparison prints the same `digest=`. A change at the boundary can
alter bytes with no error: adopting a Hash built in Rust is correct only while Rust
inserts keys in the order Ruby's canonical form expects. Name the spec that would pin
each such dependency in the report.

## Decision check

Before recommending that work move to Rust, or stay there, answer in the report:

- Is the work pure and synchronous?
- Does Ruby's object model make it slow (per-object overhead, no shared structure), or
  is it slow for a reason a Ruby fix removes?
- Is it hot per unit of user-visible work?
- Does it batch, 1 crossing per source?
- Is there a corpus or differential check that keeps both sides computing the same
  thing?

A responsiveness gain (a shorter stall) is a reason to release the GVL. It is not on
its own a reason to port.
