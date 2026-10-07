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

## 1. Check the plan is still true

- Re-check the files in the plan's Grounding section that the ready cards touch. If
  the code has moved, either note the difference in the plan or, if it breaks a card,
  ask the user with the diff and 2 or 3 options.
- If the Execution log already has entries, resume from it: skip landed cards, and
  check `git worktree list` for cards that were in flight.
- Otherwise set status to `in-progress` and record in the Execution log the base
  branch, its SHA, and the output of `git worktree list`.
- If the plan is uncommitted, commit it now so worktrees carry it. A hook failure here
  is a plan defect: fix the plan and log `plan-gap`.
- Read the repo's hook config and record in the Execution log: every check a commit
  runs, as a command an agent can run on its own paths; how long a commit takes;
  whether the suite can run beside other tests; and which paths need user approval.
- Start the friction log (below).
- Search mempalace when a card's assumption looks wrong
  (`~/.claude/reference/mempalace.md`).

## 2. Run ready cards

A card is ready when every `Depends on` card has landed, no in-flight card shares a
file with it, and it does not depend on an Open decision. Check the whole card list
each time a card lands.

For each ready card, in parallel:

1. Cut a worktree by hand from HEAD, per `references/git-protocol.md`. Never use
   `isolation: worktree`.
2. Spawn the implementer with the brief in `references/briefs.md`. Pick the agent by
   language and the model by risk.
3. Log "T<id> started" in the Execution log.

While agents run, land approved cards and start newly ready ones.

### Agent notices

A notice with no message can still mean a finished report. On every notice, read the
card's hand-back file. If there is none and the worktree has not changed in 5 minutes,
the agent is idle: continue it with SendMessage. Never wait hours on a quiet agent.

## 3. Review

In `orchestrator-commits` mode, first apply the card's wiring diffs to the shared files
in the card's worktree, so the panel reviews the card as it will land.

Spawn `panel-reviewer` for each finished card, with the brief, depth, and verdict
handling in `references/briefs.md`.

## 4. Verify and land

1. Run the full suite. If the commit hook runs the full suite, the hook run is this
   step. If it fails, follow the flaky-test procedure.
2. Land the card per `references/git-protocol.md`, as soon as it is approved and
   green. Do not batch landings.
3. Remove the card's worktree and branch.
4. Log "T<id> landed <sha>" in the Execution log and tick the card.

### Quiet box

A landing suite runs alone: 1 full suite on the box, and no agent running any test
beside it. An implementer or reviewer running 1 spec file counts.

Before each landing:

- No test process from any worktree. Load under 1 per core (`uptime`, `nproc`). High
  load with no suite running means something else is on the box: find it, then ask.
- Never beside a load proof or a second landing.

If agents keep running tests, land in windows: stop spawning, wait for running tests
to end, land every approved card in dependency order with 1 commit each, then spawn
again. If the repo has a lock that serializes suites, use it and tell agents to.

A wait loop that greps for test processes must not match its own command line.
`pgrep -f` sees the shell that runs it.

### Flaky-test procedure

No exemptions, including flakes the repo documents as known.

1. Record each failing test and the seed. Keep the hook log; a rerun overwrites it.
2. A red with no failed example is not a flake: a lint offense, a message rule, a
   short example count, a hook that modified files. Fix the cause. Never retry.
3. Wait for a quiet box. An alone-run beside working agents proves nothing.
4. Run each failing test alone, once.
5. Fails alone: a normal failure. Return it to the card's implementer.
6. Passes alone: confirmed flaky. Never re-run the suite hoping for green.
7. Run the suite with the same seed on the base commit.
   - Passes on base: the card caused it. Its implementer reproduces it, compares to
     base, and fixes the cause, continued with SendMessage. "Passes alone" can mislead:
     the agent's shell may have what the hook does not, such as a pty.
   - Fails on base: it existed before. Stop and ask the user.
   - Fails on neither after 3 tries: record it by name where the repo keeps known
     flakes, land, and log it. A repeat becomes a card.
8. Narrow the cause in at most 3 runs: same seed, `rspec --bisect`, or
   `cargo test -- --test-threads=1`.
9. Fixed means green in the suite on the failing seed and on 1 new seed.
10. The card does not land until the test is fixed or the user decides otherwise.
11. Append 1 friction entry with kind `flaky`.

## 5. Checkpoint

When no agents are in flight, write the state to the Execution log: cards landed,
cards ready, and anything blocked. Tell the user this is a clean point to `/clear` and
re-run `/execute-plan <path>`. If decisions exist that the plan does not hold, suggest
`/handoff` first. Then continue unless the user stops you.

## 6. Close out

Run the plan's Integration checks. List processes the suite may have left behind
(children of test runners, editors, servers) and stop the ones this run started. Set
status to `done`. Confirm `git worktree list` and `git branch --list` match the start
of the run. Summarize: what landed, what the panel caught, what went to the user, any
manual pass still owed, and the friction log path with its entry count.

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
