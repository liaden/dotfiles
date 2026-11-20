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
   path, and the earlier decisions. Pass paths, never pasted content. For code, ask for
   the naming pass in `principles.md` over classes, modules, methods, arguments, and
   variables. For a path target that covers every name in it; for a diff, the names it
   adds or changes.
4. **Report.** Read `~/.claude/reference/writing-style.md`. Give the findings ranked
   BLOCKER, SHOULD-FIX, NIT, each with its persona, then 1 verdict. Naming findings keep
   their ranked candidate names and the 1 line reason for the first. Change nothing
   unless asked.
5. **Lint comments for someone else's PR.** When the target is a PR and its author
   (`gh pr view <n> --json author -q .author.login`) is not me (`gh api user -q .login`),
   the comments get posted where teammates read them. Write each proposed comment to its
   own `.md` file in the scratch directory and run
   `vale --config ~/.vale.ini <files>`. Fix every error and warning,
   fix the suggestions that make the comment clearer, and run vale again until it is
   clean or the remaining alerts are on purpose. Show the linted text, not the draft.
   Skip this step for my own work.
