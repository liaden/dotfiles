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

## 3. Review

Spawn `panel-reviewer` for each finished card, with the brief, depth, and verdict
handling in `references/briefs.md`.

## 4. Verify and land

1. Run the full suite. If it fails, follow the flaky-test procedure.
2. Land the card per `references/git-protocol.md`, as soon as it is approved and
   green. Do not batch landings.
3. Remove the card's worktree and branch.
4. Log "T<id> landed <sha>" in the Execution log and tick the card.

### Flaky-test procedure

No exemptions, including flakes the repo documents as known.

1. Record each failing test and the seed.
2. Confirm no other agent is running the suite.
3. Run each failing test alone, once.
4. Fails alone: a normal failure. Return it to the card's implementer.
5. Passes alone: confirmed flaky. Never re-run the suite hoping for green.
6. Run the suite with the same seed on the base commit.
   - Passes on base: the card caused it. Its implementer fixes it, continued with
     SendMessage.
   - Fails on base: it existed before. Stop and ask the user.
7. Narrow the cause in at most 3 runs: same seed, `rspec --bisect`, or
   `cargo test -- --test-threads=1`.
8. Fixed means green in the suite on the failing seed and on 1 new seed.
9. The card does not land until the test is fixed or the user decides otherwise.
10. Append 1 friction entry with kind `flaky`.

## 5. Checkpoint

When no agents are in flight, write the state to the Execution log: cards landed,
cards ready, and anything blocked. Tell the user this is a clean point to `/clear` and
re-run `/execute-plan <path>`. If decisions exist that the plan does not hold, suggest
`/handoff` first. Then continue unless the user stops you.

## 6. Close out

Run the plan's Integration checks. Set status to `done`. Confirm `git worktree list`
and `git branch --list` match the start of the run. Summarize: what landed, what the
panel caught, what went to the user, any manual pass still owed, and the friction log
path with its entry count.

## Friction log

File: `~/.claude/friction/<repo>-<YYYY-MM-DD>-<plan-slug>.md`, 1 per run. Only the
main session writes, by shell append. Never read it during a run.

```bash
echo "$(date +%FT%H:%M) | execute-plan | step 4 | flaky | T3 | spec \"X retries\" red in suite, green alone | 2 reruns | rule should name rspec --bisect" >> ~/.claude/friction/<file>
```

Fields: time, skill, step, kind, card, what happened, cost, suggested fix.

Kinds: `plan-gap`, `skill-gap`, `tool`, `env`, `flaky`, `base`, `permission`.

Write an entry on: a question sent to the user, a wrong card assumption, a retry, a
blocked permission, a confirmed flaky test, or any step where this skill did not say
what to do.

To use the log later, run `/critique ~/.claude/friction` and ask for skill edits.
