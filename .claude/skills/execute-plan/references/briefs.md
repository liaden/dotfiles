# Briefs and review policy

Briefs pass paths. Never paste a plan, a card, or a diff into a prompt.

Never restate repo rules in a brief. Agents read the repo `CLAUDE.md`. If agents keep
missing a rule, the fix belongs in the repo `CLAUDE.md`. Log a friction entry.

Write a brief as literal text, from a quoted heredoc or a file. A command in a brief is
a line to run, placed where it runs, never a condition to meet.

## Models

| Agent | Default | High risk or high depth |
|---|---|---|
| implementer | sonnet (agent default) | `model: opus` |
| panel-reviewer | sonnet (agent default) | `model: opus` |
| spike, Explore | sonnet | sonnet |

Card risk sets the implementer's model. Review depth sets the reviewer's. Fable only
when the user asks for it on a named card.

## Implementer brief

Agent: `ruby-implementer` or `rust-implementer`, by the plan's language. Other
languages use `general-purpose` with the same brief plus
`~/.claude/reference/coding.md` named as required reading.

```
Work only in <absolute worktree path>.
Plan: <absolute plan path>. Your card: T<id>. Read the card and the plan's Shared
files section.
Repo rules: <worktree path>/CLAUDE.md. Also read ~/.claude/reference/coding.md.
Environment: <per-worktree exports from the Execution log, such as a build output
dir or TMPDIR | none>. Specs known red in a fresh worktree: <names | none>.
Scope: the card's Files list. Do not edit shared files; hand back 1-line diffs for
them. When the card's work is done and checked, stop and report. Add no tests, files,
docs, or refactors the card did not ask for; name them in the hand-back instead.
A stop condition that fires is a report, never a judgment call. Clear one only with
evidence in the hand-back; otherwise stop.
Git: <"read-only git only: status, diff, log. Never a command that writes, including
stash" | "commit on card/<card>, then rebase on <BASE> and run the full suite">. To
show a red run without git, copy the file aside, run, copy it back.
Tests first, from the card's acceptance criteria, in the spec files the card names.
Record the failing run before any production code exists. A red made by reverting
finished code is not a failing run.
Run by path: the card's spec files; every spec that names a class, duck, or symbol
you changed (grep the spec tree); every spec that builds or scripts the changed object
(seams, e2e, fixtures, exact member lists, scripted tool calls); and the ratchet
specs: <list from the Execution log>. A directory run can skip tagged files. Check a
computed file list is not empty before passing it to the runner: an empty list runs
the whole tree.
Checks: <each check a commit runs, as a command on your paths>. Run them on every file
you changed, not only the card's list, and read the inspected-file count. Never run
the commit hook or the full suite. Full suite: <"the main session runs it" | "run it
after rebase">.
Before reporting done, run a check that exercises the change. A syntax check or a
command that failed to start does not count.
Box: run every test, build, or probe as 1 command under the lock, never a loop:
  flock -s <repo>/tmp/gate.lock true && flock -s <repo>/tmp/suite.lock <command>
Never a bare whole-tree run. Never run_in_background. Never pgrep -f or pkill -f.
Wait for every command you start. No bare cat in a compound command. A probe that
spawns processes is bounded: a counted loop under timeout.
Keep working until the card is done. Stop only on a stop condition or when you cannot
continue without the main session.
Paths that need user approval: <from the Execution log | none>.
Write the full hand-back to <worktree path>/.handback-T<id>.md: files changed, failing
run, passing run, wiring diffs, surprises.
Return under 10 lines plus that path.
```

When an implementer stops with a question, research and answer it in the main session
first. Ask the user only if still blocked. Continue the same agent with SendMessage.

### Fix-round message

Every fix round, and every scope ruling that adds work, restates:

```
Items: <list>. For each item: the failing test first, record its red run, then the
code. A fix with no red run is re-proved by the reviewer backing it out.
Same scope, same git rule, same lock line as your brief.
Rerun the card's specs and the ratchet list before reporting.
```

## Reviewer brief

Agent: `panel-reviewer`. It runs in the card's worktree and gets none of its own.

```
Review card T<id> of <absolute plan path> in <absolute worktree path>.
Language: <language>. Roster: <panel line from the plan>.
Hand-back: <worktree path>/.handback-T<id>.md.
Wiring applied by the main session: <shared files | none>. Review it too.
Depth: <low | medium | high>.
Git: read-only only: status, diff, log. Never stash, checkout, or any write.
Never edit the work. Mutate a copy: cp -r the worktree without .git to <scratch
path>, mutate there under bash, and cmp the worktree against the copy before
reporting. Probe scripts go under <worktree path>/tmp/probes/. Return findings
inline.
Run spec files by path, including any the repo tags as slow. Never the full suite and
never a bare whole-tree run: the main session runs the suite. Each run is 1 command
under the lock:
  flock -s <repo>/tmp/gate.lock true && flock -s <repo>/tmp/suite.lock <command>
Never run_in_background. Wait for every command you start.
A drive of the real binary uses an isolated state dir and a private tmux socket.
Judge the failing run in the hand-back: was it red before the code existed?
Check every comment against the WHY-only rule in ~/.claude/reference/coding.md.
Ratchet specs for this repo: <list from the Execution log>.
```

Add at medium depth: "Back out each production change in turn and confirm a criterion
goes red." At high depth: "Drive the real system the card touches: real data, real
history, a real terminal, every reader of the changed value." For a card whose tests a
later card deletes: "Judge whether the replacement can fail."

## Review policy

| Card risk | Depth |
|---|---|
| low | low |
| medium | medium |
| high | high |

| Verdict | Action |
|---|---|
| APPROVE | Verify and land |
| APPROVE-WITH-FIXES, all mechanical | Same implementer applies them. No second review |
| APPROVE-WITH-FIXES with a substantive fix, or REQUEST-CHANGES | Same implementer fixes, showing a failing test before each fix. 1 second review |
| Second review: mechanical findings only, or a BLOCKER with a verified fix | Same implementer applies them. The main session verifies a diff under about 20 lines; a larger one gets a narrow re-check by the same reviewer over SendMessage. Not a review round |
| Second review: a substantive finding | 1 more fix round and a third review. If the third still requests changes, stop and ask the user |
| Implementer shows a required fix is wrong | It reverts the fix and hands back the evidence and a substitute. The same reviewer rules on both by SendMessage. The ruling is not a review round |

- A probe that found a defect becomes a spec in the fix round.
- A green suite is no reason to skip review.
- A fix that must touch files from a landed card is a scope change. Decide it in the
  main session and note it in the Execution log.
- A flake fix outside any card follows the same rounds as a card. Approved cards that
  do not touch the flaky test land past it.
- A standing user ruling recorded in memory answers a policy question here. Follow it
  and log `worked`.
