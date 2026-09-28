---
name: critique
description: Review research, a plan, a PR, staged code, or the changes a finished plan made, as a panel of named reviewers. Use when asked to critique or review work.
argument-hint: <path, PR number, or "staged">
---

# critique

1. **Work out the target.** A path is a file or directory. A number is a PR: use
   `gh pr diff <n>`. "staged" is `git diff --cached`. With no argument, use the work
   discussed in this session, and ask if that is unclear. Save a diff to a file in the
   repo's scratch directory.
2. **Search mempalace** for earlier decisions on the same code or topic
   (`~/.claude/reference/mempalace.md`). Note the ones a reviewer should know.
3. **Spawn `panel-reviewer`.** Pass the target paths, the language, the repo `CLAUDE.md`
   path, and the earlier decisions. Pass paths, never pasted content.
4. **Report.** Read `~/.claude/reference/writing-style.md`. Give the findings ranked
   BLOCKER, SHOULD-FIX, NIT, each with its persona, then 1 verdict. Change nothing unless
   asked.
