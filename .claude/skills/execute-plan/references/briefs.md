# Briefs and review policy

Briefs pass paths. Never paste a plan, a card, or a diff into a prompt.

Never restate repo rules in a brief. Agents read the repo `CLAUDE.md`. If agents keep
missing a rule, the fix belongs in the repo `CLAUDE.md`. Log a friction entry.

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
Scope: the card's Files list. Do not edit shared files; hand back 1-line diffs for
them. When the card's work is done and checked, stop and report. Add no tests, files,
docs, or refactors the card did not ask for; name them in the hand-back instead.
Git: <"never run git, including stash" | "commit on card/<card>, then rebase on <BASE>
and run the full suite">. To show a red run without git, copy the file aside, run,
copy it back.
Tests first, from the card's acceptance criteria, in the spec files the card names.
Record the failing run before any production code exists. A red made by reverting
finished code is not a failing run.
Run by path: the card's spec files; every spec that names a class, duck, or symbol
you changed (grep the spec tree); and <the repo's suite-wide ratchet specs | none>. A
directory run can skip tagged files.
Checks: <each check a commit runs, as a command on your paths>. Never run the commit
hook or the full suite. Full suite: <"the main session runs it" | "run it after rebase">.
Before reporting done, run a check that exercises the change. A syntax check or a
command that failed to start does not count.
Keep working until the card is done. Stop only on a stop condition or when you cannot
continue without the main session. Wait for every command you start.
Paths that need user approval: <from the Execution log | none>.
Write the full hand-back to <worktree path>/.handback-T<id>.md: files changed, failing
run, passing run, wiring diffs, surprises.
Return under 10 lines plus that path.
```

When an implementer stops with a question, research and answer it in the main session
first. Ask the user only if still blocked. Continue the same agent with SendMessage.

## Reviewer brief

Agent: `panel-reviewer`. It runs in the card's worktree and gets none of its own.

```
Review card T<id> of <absolute plan path> in <absolute worktree path>.
Language: <language>. Roster: <panel line from the plan>.
Hand-back: <worktree path>/.handback-T<id>.md.
Wiring applied by the main session: <shared files | none>. Review it too.
Depth: <low | medium | high>.
Never run git. Write only probe scripts, under <worktree path>/tmp/probes/. Return
findings inline.
Run spec files by path, including any the repo tags as slow.
Judge the failing run in the hand-back: was it red before the code existed?
Check every comment against the WHY-only rule in ~/.claude/reference/coding.md.
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
| APPROVE-WITH-FIXES with a substantive fix, or REQUEST-CHANGES | Same implementer fixes, showing a failing test before each fix. 1 second review, no third |
| Implementer shows a required fix is wrong | It reverts the fix and hands back the evidence and a substitute. The same reviewer rules on both by SendMessage. The ruling is not a review round |

- A probe that found a defect becomes a spec in the fix round.
- A green suite is no reason to skip review.
- A fix that must touch files from a landed card is a scope change. Decide it in the
  main session and note it in the Execution log.
- If the second review still requests changes, stop and ask the user.
