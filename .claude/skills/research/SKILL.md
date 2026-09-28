---
name: research
description: Explore an idea or question, compare options, and write a report. Use when asked to research, investigate options, or brainstorm an approach before planning.
argument-hint: <question or idea>
---

# research

The output is a report that compares options and recommends 1. Write no production
code. To build a corpus of papers and sources, use `/research-corpus`.

## 1. Check the branch

```bash
git fetch origin
default=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)
git rev-list --count HEAD.."$default"
git log -1 --format=%cs HEAD; git log -1 --format=%cs "$default"
```

If the branch is 50 commits behind the default branch, or its last commit is 14 days
older than the default branch's, ask the user: research the current state, or a
worktree at the updated default branch.

For the worktree:

```bash
git check-ignore -v tmp/                       # must print a rule
git worktree add --detach tmp/worktrees/research-<slug> "$default"
```

The worktree has no untracked planning files. Read prior research from the main
checkout and write the report there. Remove the worktree at the end.

## 2. Find prior research

Glob `*research*` under `planning/` and `references/`. Check `references/INDEX.md`.
Search mempalace (`~/.claude/reference/mempalace.md`). List what exists, with dates,
and ask whether to include it. Do not read the content before the answer. Prior
research can anchor the result, and the user may want a fresh view.

## 3. Look up, then ask

Look up anything a file or a code search can answer. Use AskUserQuestion only for
goals, constraints, users, and taste.

## 4. Explore

Compare at least 3 options, including "do nothing" and "use an existing library".
Read `~/.claude/reference/principles.md` for the grounds to judge them on. Send
parallel Explore agents for code questions. Use web search for prior work and
standards, capped at about 10 searches unless the user widens it. Keep the URL and the
date for every source used.

## 5. Spike

When an option rests on an unverified assumption, spawn the `spike` agent with the
question and an absolute path to a throwaway worktree:

```bash
git worktree add tmp/worktrees/spike-<slug> -b spike/<slug> HEAD
# after the agent reports
git worktree remove --force tmp/worktrees/spike-<slug>
git branch -d spike/<slug>
```

## 6. Write

Read `~/.claude/reference/writing-style.md`. Fill `references/report-template.md`.
Save as `planning/<topic>-research-<YYYY-MM>.md` in the main checkout. If the repo has
no `planning/`, ask for a location (pigmentarium keeps plans at the repo root).

Reply with the recommendation in under 5 lines, the open questions, and the report
path. Confirm `git worktree list` matches the start.
