# Profiling report template

````markdown
# <Topic>: profiling

| | |
|---|---|
| Date | <YYYY-MM-DD> |
| Git SHA | <short sha> |
| Stack | <Ruby x.y.z, YJIT on or off; rustc x.y; extension build flags> |
| Box | <CPU, RAM, load average range during the runs, anything else running> |
| Prior work | <files read, or "none found"> |
| Evidence | `<report name>/`: bench scripts, flamegraphs, spike diffs, trial records |

## Summary

<Under 100 words. Where the cost is, with its share. The top fix and its measured gain.
The main risk.>

## Question and workload

<The question. The command that shows it. The size (turns, files, items) and why that
size. The metric.>

## Method

<The scratch copy and build commands. 1 table: what was measured, the command, the
tool and its settings. Tool versions. What each profiler could not see.>

## Baseline

| | <case 1> | <case 2> |
|---|---|---|
| runs | <values, with load average> | |

<The time split: wall, user, sys, children, GC. The phase table, median of N.>

## Where the cost is

<Top 10 frames by self and by total, per case. The split by library for a native
extension. Flamegraph file names.>

## Why

<For each hot spot: what the code does, with path:line, and why it runs that often or
that long. Who pays: spec, application, or both.>

## Candidates

### 1. <Name> (<measured | reproduced | read | estimated>)

<Where the change goes. The A/B table: arms, median, ratio, interval, n. Which phase
shrank and which grew. Risks to correctness and invariants, and the spec that would pin
each.>

### Measured and rejected

<Each with its numbers and 1 line of reason.>

## Lenses that showed nothing

<GC 3% of wall, GVL wait 3%, and so on, 1 line each with the number.>

## Ranked recommendation

<Numbered. Gain, size of the change, and status for each. What would change the order.
How sure you are.>

## Open questions

<What the round could not answer, and what run or which person could.>

## Sources

<Files with paths, tools with versions, URLs with the date read, papers.>
````
