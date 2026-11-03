---
name: execute-plan
description: Run a plan written by /create-plan. One agent per task card in its own worktree, a panel review per card, and the main session owns commits.
argument-hint: <path to plan>
disable-model-invocation: true
---

# execute-plan

You are the main session. Agents implement and review. You coordinate, verify, commit,
and ask the user when blocked. Read the whole plan first.

Your context is the cost that grows through the run. Agents return short summaries and
file paths. Evidence and probe scripts stay in files.

This skill wins over the repo `CLAUDE.md` on flaky tests. The repo wins on everything
else.

Main-session habits. Each one has cost a full suite run when it slipped:

- Never `cd` into a worktree. Use `git -C` and absolute paths. A `cd` moves a running
  agent's shell too.
- Never write a tracked file in the main checkout while a landing hook runs. Keep the
  running Execution log in the scratchpad, by absolute path, and fold it into the plan
  between landings.
- Landing work runs from a script file under `bash` with `set -e`, with paths read
  from a file. Never a zsh one-liner: zsh does not word-split an unquoted variable.
- Wait with `references/wait-quiet.sh` or on a task notification. Never an inline
  `pgrep -f` loop and never `pkill -f`: a waiting shell matches its own command line.
  Stop a process by pid.

## 1. Check the plan is still true

- Re-check the files in the plan's Grounding section that the ready cards touch. If
  the code has moved, either note the difference in the plan or, if it breaks a card,
  ask the user with the diff and 2 or 3 options.
- If the Execution log already has entries, resume from it: skip landed cards, and
  check `git worktree list` for cards that were in flight. A landing runner from an
  earlier session may still be running: find it by pid before starting another.
- Otherwise set status to `in-progress` and record in the Execution log the base
  branch, its SHA, `git worktree list`, and `git status --porcelain` including staged
  entries. Unstage pre-staged user work for the run and record the command that
  re-stages it at close-out.
- If the plan is uncommitted, commit it now so worktrees carry it. A hook failure here
  is a plan defect: fix the plan and log `plan-gap`. If the user holds landings, defer
  the commit and have agents read the plan by absolute path. Never leave plan edits
  unstaged during a landing: the hook stashes them and agents see no card.
- Read the repo's hook config and record in the Execution log: every check a commit
  runs, as a command an agent can run on its own paths; how long a commit takes;
  whether the suite can run beside other tests; how to read the example count when a
  passing hook prints nothing (a verbose flag, the runner's own log); and which paths
  need user approval.
- Build the repo's ratchet list once and put it in every brief: specs that scan `lib/`
  or the whole tree, pin an exact member list, or check a census. Find them by grep
  (`Dir.glob`, `Dir[`, `File.read` of a source path, `contain_exactly` over a
  catalog), never by a top-level glob alone.
- List the gitignored build outputs the suite needs in a fresh worktree: compiled
  extensions, release binaries, the runtime log a parallel runner groups by. The cut
  step copies them. Record which specs go red or pend without them.
- Pick a worktree prefix from the plan slug. Card ids repeat across plans, and stale
  `card/T<id>` branches collide.
- Start the friction log (below).
- Search mempalace when a card's assumption looks wrong
  (`~/.claude/reference/mempalace.md`).

## 2. Run ready cards

A card is ready when every `Depends on` card has landed, no in-flight card shares a
file with it, and it does not depend on an Open decision. Check the whole card list
each time a card lands.

A card whose only block is a parent that is approved or in review may start stacked on
that parent, per the stacking recipe in `references/git-protocol.md`. Docs-only tail
cards start as soon as what they describe has landed. Never stack from a worktree whose
reviewer is still running.

Cap concurrent agents by memory, about 1 per 2 GB of RAM, with a landing suite counted
as 1. Spawn only between landings. A fresh worktree never runs a from-scratch build.

For each ready card, in parallel:

1. Cut a worktree by hand from HEAD, per `references/git-protocol.md`. Never use
   `isolation: worktree`.
2. Spawn the implementer with the brief in `references/briefs.md`. Pick the agent by
   language and the model by risk. Write the brief as literal text; an unquoted
   heredoc expands backticks.
3. Log "T<id> started" in the Execution log with `$(date +%H:%M)`, never a typed time.

While agents run, land approved cards and start newly ready ones.

### Agent notices

A notice with no message can still mean a finished report. On every notice, read the
card's hand-back file. If there is none and the worktree has not changed in 5 minutes,
the agent is idle: continue it with SendMessage. A tool call that has not returned in
10 minutes is idle too. An agent idle again after 1 nudge is stopped and replaced.
Never wait hours on a quiet agent.

A fired stop condition is a report. An implementer that works around one, or clears
one without evidence, is sent back to it.

### Fix rounds

Every fix round sent by SendMessage restates: tests first, 1 failing run per item
before its code, and that a missing red is re-proved by the reviewer backing the fix
out. Agents skip the red in fix rounds unless told again.

## 3. Review

Before spawning the reviewer, in the card's worktree:

1. In `orchestrator-commits` mode, apply the card's wiring diffs to the shared files,
   so the panel reviews the card as it will land.
2. Run the commit's lint checks on every file the wiring touched. A wiring line that
   pushes a spec past the line limit fails the hook after a green suite.
3. Send the review only after both are on disk, never in the same turn as the edit.

Spawn `panel-reviewer` for each finished card, with the brief, depth, and verdict
handling in `references/briefs.md`. Never spawn a reviewer while a landing holds test
runs: a subagent cannot idle, so a held reviewer hands back a provisional verdict.

Never delete a reviewer's scratch copy until its review rounds are over.

## 4. Verify and land

1. Take the landing gate and wait for a quiet box (below).
2. Run the full suite. If the commit hook runs the full suite, the hook run is this
   step. If it fails, follow the flaky-test procedure.
3. Land the card per `references/git-protocol.md`, as soon as it is approved and
   green. Do not batch landings.
4. Copy the card's hand-back to the scratchpad, then remove the worktree and branch.
   Remove worktrees only while no hook runs; a build step can glob into one.
5. Log "T<id> landed <sha>" in the Execution log and tick the card.

A deletion-only commit may stage no file the hook checks, so the hook skips the suite.
Run the suite by hand after such a landing.

### Quiet box

A landing suite runs alone: 1 full suite on the box, and no agent running any test,
compile, mutation sweep, or load probe beside it. An implementer or reviewer running
1 spec file counts. Load under 1 per core (`uptime`, `nproc`). High load with no
suite running means something else is on the box: find it, then ask.

Agents keep tests going, so a quiet moment never comes on its own. Use 2 lock files
in the repo's ignored `tmp/`: a gate and a suite lock.

Every brief carries this line as the only way to run anything that loads the box,
1 command per hold, never a loop and never a bare whole-tree run:

```bash
flock -s <repo>/tmp/gate.lock true && flock -s <repo>/tmp/suite.lock <single command>
```

The landing takes the gate exclusive, which stops new runs, then the suite lock
exclusive, which waits for running ones, then checks load and commits inside both:

```bash
flock -x tmp/gate.lock -c "flock -x tmp/suite.lock -c '<wait-quiet> && <land script>'"
```

`references/wait-quiet.sh` is the wait. It counts only non-shell processes that match
the pattern, so no waiting shell can match itself, and it checks load. Pass the repo's
test-runner pattern from the Execution log. Hold the gate from the load check through
the commit. A check followed by a commit is not a window.

If a background hook job gets killed under memory pressure, run the hook in the
foreground and stop agents' heavy probes before the next landing.

When you pause agents by message, keep the held-agents list in a scratch file and
resume from it. Hold only agents whose runs would overlap the window. A pause message
says: cancel queued and waiting runs too, not only the current one.

### Flaky-test procedure

No exemptions, including flakes the repo documents as known.

1. Record each failing test and the seed. Keep the hook log; a rerun overwrites it.
2. A red with no failed example is not a flake: a lint offense, a message rule, a
   short example count, a hook that modified files. Fix the cause. Never retry.
3. Wait for a quiet box. An alone-run beside working agents proves nothing.
4. Run each failing test alone, once.
5. Fails alone: a normal failure. Return it to the card's implementer.
6. Passes alone: confirmed flaky. Never re-run the suite hoping for green.
7. Restore the card's copied files first: `git reset` leaves them on disk. Then run
   the failing file with its worker's seed, 3 times, on the base commit. Under a
   runtime-grouped parallel runner the suite seed is not the file's seed.
   - Green 3 of 3 on base: the card caused it. Its implementer reproduces it, compares
     to base, and fixes the cause, continued with SendMessage. "Passes alone" can
     mislead: the agent's shell may have what the hook does not, such as a pty or open
     std fds.
   - Red on base: it existed before. Record it by name where the repo keeps known
     flakes and land the card. A name already on that list, retired or not, or already
     in this run's log, is a repeat: it becomes a card, and the landing still goes.
   - Neither reproduces after 3 tries: record it by name, land, and log it. A repeat
     becomes a card.
8. Narrow the cause in at most 3 runs: same seed, `rspec --bisect`, or
   `cargo test -- --test-threads=1`.
9. Fixed means green in the suite on the failing seed and on 1 new seed.
10. A test the card caused is fixed before the card lands, or the user decides
    otherwise.
11. A repeat card that finds no defect, where the only fix is a looser threshold, goes
    to the user as a decision.
12. Append 1 friction entry with kind `flaky`.

## 5. Checkpoint

When no agents are in flight, write the state to the Execution log: cards landed,
cards ready, and anything blocked. Commit the plan with the log; a reboot mid-hook
loses an uncommitted log to the hook's stash. Tell the user this is a clean point to
`/clear` and re-run `/execute-plan <path>`. If decisions exist that the plan does not
hold, suggest `/handoff` first. Then continue unless the user stops you.

## 6. Close out

Run the plan's Integration checks. Run the censuses at the base SHA too before blaming
a card. List processes the suite may have left behind (children of test runners,
editors, servers) and stop the ones this run started. Re-stage the user work unstaged
at step 1. After any landing that was killed mid-hook, diff the tree against the
start status and look in `~/.cache/pre-commit/patch*` for a stash the hook never
restored. Set status to `done`. Confirm `git worktree list` and `git branch --list`
match the start of the run. Summarize: what landed, what the panel caught, what went
to the user, any manual pass still owed, and the friction log path with its entry
count.

## Friction log

File: `~/.claude/friction/<repo>-<YYYY-MM-DD>-<plan-slug>.md`, 1 per run. Only the
main session writes, by shell append. Never read it during a run.

```bash
echo "$(date +%FT%H:%M) | execute-plan | step 4 | flaky | T3 | spec \"X retries\" red in suite, green alone | 2 reruns | rule should name rspec --bisect" >> ~/.claude/friction/<file>
```

Fields: time, skill, step, kind, card, what happened, cost, suggested fix.

Kinds: `plan-gap`, `skill-gap`, `tool`, `env`, `flaky`, `base`, `permission`, `worked`.

Write an entry on: a question sent to the user, a wrong card assumption, a retry, a
blocked permission, a confirmed flaky test, or any step where this skill did not say
what to do. Keep all notes on the skills here, never in a scratch file.

At close-out, write 1 `worked` entry for each rule that stopped a defect, with the
evidence. These mark what a later simplification must keep.

To use the log later, run `/critique ~/.claude/friction` and ask for skill edits.
