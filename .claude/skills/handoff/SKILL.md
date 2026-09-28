---
name: handoff
description: Write a short handoff file so a fresh session can continue this work. Use before /clear, or when context is large and the work is at a clean stopping point.
argument-hint: [what the next session should do]
---

# handoff

1. **Check for agents in flight.** If any subagent or background task is running,
   refuse and name them. They do not survive `/clear`. Offer to wait for them.
2. **Pick the location.** Use the repo's ignored scratch directory (`tmp/` if
   `git check-ignore -v tmp/` prints a rule). Outside a repo, use `~/.claude/handoffs/`.
3. **Write** `handoff-<YYYY-MM-DD>-<slug>.md`. Read
   `~/.claude/reference/writing-style.md` first. Under 400 words:

   ```markdown
   # Handoff: <topic>

   Date, repo, branch, SHA, uncommitted changes (yes or no).

   ## Goal
   ## Decisions made, and why
   ## Current state
   ## Next steps
   ## Files that matter
   ## Open questions
   ```

   - Record what the code and git history do not show: decisions, dead ends, and what
     the user said.
   - Give paths with line numbers. Paste no code.
   - If a plan is running, give its path. Its Execution log holds the card state.
   - The argument, if given, becomes the first of the next steps.

4. **Print the prompt** to paste into the new session:

   ```
   Read <absolute path to handoff file> and continue from "Next steps". Do not re-ask
   the questions it lists as decided.
   ```
