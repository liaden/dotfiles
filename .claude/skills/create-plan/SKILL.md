---
name: create-plan
description: Write a plan of task cards that /execute-plan can run. Checks the real code first, asks what the code cannot answer, and gets a panel review. Use when asked to plan a feature or a roadmap item.
argument-hint: <what to plan>
---

# create-plan

The output is a plan document that a fresh session can run with `/execute-plan` and no
other context. Write no implementation code. The repo `CLAUDE.md` wins over this skill.

Log friction as `execute-plan` does, in
`~/.claude/friction/<repo>-<YYYY-MM-DD>-plan-<slug>.md`.

## 1. Check the code

Read the repo `CLAUDE.md`, `planning/`, and `references/`. Search mempalace for prior
decisions (`~/.claude/reference/mempalace.md`). Send parallel Explore agents to check
every file the work touches: current behavior, code worth reusing, and the specs that
pin it. List where docs and code disagree.

## 2. Settle backwards compatibility

1. List the surfaces the plan touches: public APIs, CLI flags, config files, stored
   data, serialized formats.
2. Gather evidence for each, all by lookup: gemspec and `Cargo.toml` version and
   `publish` flag, git tags, `CHANGELOG.md`, `pub` items and YARD `@api` tags, consumers
   found by grep across `~/dev`, migrations and schema files, serialized structs, and
   mempalace.
3. Give each surface a verdict:
   - Outside consumers or stored data exist: **must keep**.
   - None, and the surface is unpublished or internal: **free to break**.
   - Unclear or conflicting evidence: ask the user.
4. For each must-keep surface, check whether breaking it would allow a large
   simplification: it removes a card, removes an abstraction layer, or cuts about 20% of
   the plan. If so, report the trade before cutting cards. The user decides.

```
Surface: <name>
Keeping it costs: <cards, files, or code paths>
Breaking it allows: <what gets deleted or merged>
Who is affected: <consumers or data found, with paths>
Migration: <1 line, or "none needed">
```

Record every verdict in the plan's Compatibility section.

## 3. Ask

Use AskUserQuestion only for what code and files cannot answer: policy, scope, taste,
and where the plan should live if the repo has no planning location. If the language
has no roster in `~/.claude/reference/rosters.md`, propose one and confirm it.

## 4. Design

Read `~/.claude/reference/principles.md`. Look for refactors and simplifications first.
Each one becomes a card or a rejected option with a reason.

## 5. Spike when it lowers risk

When a card depends on an unverified assumption about a library, a performance limit,
or an API, test it before planning around it:

```bash
git check-ignore -v tmp/                                  # must print a rule
git worktree add tmp/worktrees/spike-<slug> -b spike/<slug> HEAD
# spawn the spike agent with the question and the absolute worktree path
git worktree remove --force tmp/worktrees/spike-<slug>
git branch -d spike/<slug>
```

Record the question, result, and evidence in the plan's Spike findings.

## 6. Cut into cards

Write cards per `references/task-card.md`. Set the risk on each card. List the shared
files that only the main session edits. Draw the dependency graph in mermaid. Default
`commit-mode` is `orchestrator-commits`.

## 7. Lint, then panel review

Run every check in `references/lint.md` and fix failures. Then spawn `panel-reviewer`
with the plan path, the repo `CLAUDE.md` path, and the language. Ask it to trace 1
capability backwards from the real entry point and name where it is constructed. Fix
BLOCKERs and substantive SHOULD-FIXes, then list what the panel changed.

## 8. Write

Read `~/.claude/reference/writing-style.md`. Fill `references/plan-template.md`.
Include code snippets for new interfaces and mermaid diagrams for flow or structure.
Save to the repo's planning location (`planning/specs/<slug>.md` in lain), add 1 line
to the repo's roadmap or index, and tell the user the plan runs with
`/execute-plan <path>`.
