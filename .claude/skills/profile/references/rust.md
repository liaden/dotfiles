# Rust

Profile the release build with symbols. A debug build has a different hot list.

Figures marked "1 measurement" come from 1 project on 1 box. They show the scale a
cost can reach. They are never a threshold: measure the project in front of you.

## The build

```bash
CARGO_PROFILE_RELEASE_DEBUG=true CARGO_PROFILE_RELEASE_STRIP=false cargo build --release
file target/release/<bin>          # must say "with debug_info, not stripped"
```

The environment variables leave `Cargo.toml` alone. For a project that profiles often,
propose a profile:

```toml
[profile.profiling]
inherits = "release"
debug = true
strip = false
```

- Stack walking: `--call-graph dwarf` works on any build and writes large files.
  Frame pointers are cheaper and walk deeper: `RUSTFLAGS="-C force-frame-pointers=yes"`,
  then `--call-graph fp`. The standard library still lacks them unless rebuilt.
- `lto` and `codegen-units = 1` inline across crates, so a hot callee can vanish into
  its caller. Profile the configuration that ships, and read inlined frames with
  `perf report --inline` or `perf script --inline`.
- `panic = "abort"` and `opt-level` changes are A/B candidates, not profiling settings.

## Lenses

| Lens | First tool | Others |
|---|---|---|
| cpu | `perf record` + inferno | `cargo flamegraph`, `samply` |
| cpu, small and exact | criterion bench | `perf stat`, iai-callgrind |
| wall, off-CPU | `offcputime` | `perf trace -s`, `strace -c`, tokio-console |
| lock contention | off-CPU stacks ending in `futex` | `strace -f -c -e trace=futex`, `perf trace -s` |
| memory, allocations | heaptrack | dhat (crate or valgrind), bytehound |
| memory, peak and leaks | `/usr/bin/time -v`, heaptrack | bcc `memleak`, jemalloc profiling |
| binary and build | `cargo bloat`, `cargo build --timings` | `cargo llvm-lines` |

## CPU

```bash
perf record -F 999 --call-graph dwarf,32768 -o evidence/perf.data -- target/release/<bin> <args>
perf report -i evidence/perf.data --no-children --sort dso,symbol --stdio | head -60
perf script -i evidence/perf.data | inferno-collapse-perf | inferno-flamegraph > evidence/cpu.svg
```

- `-F 999` avoids locking onto a 1,000 Hz timer. Drop to `-F 49` for a run of minutes;
  dwarf stacks at 999 Hz fill the disk.
- `32768` is the stack bytes copied per sample. Deep recursion needs it; the default
  8,192 truncates stacks, which shows as many roots in the flamegraph.
- Attach to a running process after setup: `perf record ... -p <pid> -- sleep 30`.
- `--sort dso` first. It says how much is your crate, libc (`malloc`, `memcpy`), and
  the kernel, before any function name.
- `cargo flamegraph --bin <bin> -- <args>` wraps the same pipeline.
- `samply record --save-only -o evidence/samply.json -- target/release/<bin>` records
  for the Firefox Profiler; `samply load` serves it for the user.
- inferno, `flamegraph`, and `samply` come from `cargo install`. Ask before installing.

What the frames usually mean:

| Frame | Usual cause |
|---|---|
| `malloc`, `free`, `realloc`, `__rust_alloc` | allocation in a loop: `clone`, `to_string`, `collect`, `format!`, a `Vec` grown without `with_capacity` |
| `memcpy`, `memmove` | large values moved or cloned; `Vec` growth |
| `core::hash::sip` | default `HashMap` hasher on a hot map. Try `rustc-hash` or `ahash`, and measure: when the walk is pointer chasing the hasher changes nothing |
| `core::fmt` | formatting on the hot path |
| `drop_in_place` | freeing a big structure; often the mirror of the allocation cost |
| `Arc` `fetch_add`, `fetch_sub` | reference counts cloned per item |
| `Mutex::lock`, `futex` | contention; go to the off-CPU lens |
| `regex` compile, parser or query constructors | a compiled object rebuilt per call. Cache it (2.6 ms per call for 1 query compile, 1 measurement) |

`perf stat -d <command>` gives instructions per cycle, cache misses, and branch misses
when the profile is flat and the cost is the memory hierarchy. `perf annotate <symbol>`
shows the hot instructions.

## Benchmarks

- criterion: `cargo bench -- --save-baseline base`, change the code, then
  `cargo bench -- --baseline base`. It reports the change with an interval. It runs
  both sides in 1 layout each, so confirm a small gain with `scripts/ab.rb` on a
  binary or an example.
- `std::hint::black_box` around inputs and results, or the optimizer deletes the work.
- Bench at the real size and with real data shapes. A 50,000-entry input finds what a
  100-entry input hides.
- iai-callgrind counts instructions. It is stable enough for CI and blind to cache and
  syscall cost.
- A thread-local cache is cold on every new thread. If production runs each call on a
  fresh thread, the bench must too.

## Wall, off-CPU, and locks

```bash
strace -f -c -o evidence/strace.txt target/release/<bin>          # syscall counts and time
strace -f -c -e trace=futex -o evidence/futex.txt target/release/<bin>   # time parked on locks and condvars
perf trace -s -o evidence/trace.txt -- target/release/<bin>       # the same summary per thread, lower overhead
inferno-flamegraph --colors io < evidence/off.txt > evidence/offcpu.svg
```

Root, run by the user: `offcputime -p <pid> -f 30 > evidence/off.txt` records the
blocked stacks that the last line draws.

- Off-CPU stacks need frame pointers to be readable.
- **Lock contention.** A contended `std::sync::Mutex`, `RwLock`, or `Condvar` parks
  in the `futex` syscall, so contention shows as `futex` time and call counts, and as
  off-CPU stacks that end in `futex_wait` under the lock's caller. An uncontended lock
  never enters the kernel. Time in `futex` also counts idle waits (a worker parked on
  an empty channel); split by thread before calling it contention.
- `perf lock` reports kernel locks only and cannot see a userspace mutex. Do not use
  it for this.
- The commands in this section were written from documentation and have not been run
  by this skill yet. Check each tool's `--help` first, and log a `ref-wrong` friction
  entry on any mismatch.
- Async: a future that blocks (file I/O, a long CPU loop, a `std::sync::Mutex` held
  across `.await`) stalls every task on that worker. `tokio-console` shows tasks with
  long poll times; it needs the `console-subscriber` crate and `tokio_unstable`.
- `runqlat` (bcc) shows time spent runnable and waiting for a CPU. High values mean the
  box is oversubscribed, and no code change fixes that.

## Memory

```bash
/usr/bin/time -v target/release/<bin>      # peak RSS, page faults
heaptrack -o evidence/heap target/release/<bin> <args>
heaptrack_print evidence/heap.zst | head -100     # heaptrack prints the exact file name it wrote
heaptrack_print -F evidence/heap-stacks.txt evidence/heap.zst && inferno-flamegraph < evidence/heap-stacks.txt > evidence/alloc.svg
```

heaptrack reports allocation counts, temporary allocations (freed right after), peak
contributors, and leaks, each by stack. It needs debug info and slows the program
several times.

dhat as a crate gives the same from inside, with no external tool:

```rust
#[cfg(feature = "dhat-heap")]
#[global_allocator]
static ALLOC: dhat::Alloc = dhat::Alloc;

fn main() {
    #[cfg(feature = "dhat-heap")]
    let _profiler = dhat::Profiler::new_heap();
    // ...
}
```

It writes `dhat-heap.json` at exit, read with dhat's `dh_view.html`. Keep it behind a
feature. dhat can also assert allocation counts in a test, which pins a fix.

- Temporary allocations are the cheapest win: reuse a buffer, take `&str` where a
  `String` is built and dropped, `with_capacity`.
- A structure that never shrinks (a memo, an interner, an arena) reads as a leak in
  RSS and not in a leak checker. Report its size at the workload's end and what bounds
  it.
- Requested bytes differ from resident bytes. Thread stacks and large reservations are
  mapped in full and touched in part.
- Allocator A/B (`tikv-jemallocator`, `mimalloc`) is a 3-line change and a real
  candidate for allocation-heavy code. Measure time and peak RSS.
- jemalloc heap profiling (`MALLOC_CONF=prof:true,...` with the `profiling` feature)
  suits a long-running service where heaptrack's slowdown is too much.

## Binary and build

Only when the question is size or compile time: `cargo bloat --release --crates`,
`cargo llvm-lines` for generic bloat, `cargo build --timings` for the build graph.

## Traps

- A stripped binary gives hex addresses. Check `file` before recording.
- `perf` without stacks (`-g` missing) gives self time only, with no callers.
- Timing with `Instant` inside a function the optimizer inlines can move the cost.
  Time at the call site of a `#[inline(never)]` function when laps look odd.
- A bench that runs under `cargo test` uses the test profile, which is unoptimized.
- A change that speeds 1 operation can slow construction (pre-segmenting candidates cut
  a query from 56 ms to 16 ms and added 44 ms to the constructor, 1 measurement).
  Bench both.
