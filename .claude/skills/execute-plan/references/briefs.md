# Briefs and review policy

Briefs pass paths. Never paste a plan, a card, or a diff into a prompt.

## Implementer brief

Agent: `ruby-implementer` or `rust-implementer`, by the plan's language. Other
languages use `general-purpose` with the same brief plus
`~/.claude/reference/coding.md` named as required reading.

Model by risk: low and medium use the agent's default. High passes `model: opus`.

```
Work only in <absolute worktree path>.
Plan: <absolute plan path>. Your card: T<id>. Read the card and the plan's Shared
files section.
Repo rules: <worktree path>/CLAUDE.md. Also read ~/.claude/reference/coding.md.
Scope: the card's Files list. Do not edit shared files. Hand back 1-line diffs for
them.
Git: <"never run git" | "commit on card/<card>, then rebase on <BASE> and run the
full suite">.
Tests first, from the card's acceptance criteria, in the spec files the card names.
Stop and report on any of the card's stop conditions.
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
Depth: <low | medium | high>.
Save probe scripts under <worktree path>/tmp/probes/.
Check every comment against the WHY-only rule in ~/.claude/reference/coding.md.
```

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

- A probe that found a defect becomes a spec in the fix round.
- A green suite is no reason to skip review.
- A fix that must touch files from a landed card is a scope change. Decide it in the
  main session and note it in the Execution log.
- If the second review still requests changes, stop and ask the user.
