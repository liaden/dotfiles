# Coding rules

The repo `CLAUDE.md` wins where it disagrees with this file.

## Comments

- Comments explain WHY only, and are rare: a constraint, a trade, a bug the obvious code
  would bring back.
- If code seems to need a WHAT comment, refactor so it reads clearly: rename, extract a
  method, or split the function.
- 1 line where possible. Longer reasoning goes in the commit message.
- No comments that name a plan, a card, a ticket step, or the author.

## Tests

- Tests first. Write the test, run it, and show it fails for the expected reason. Then
  write the code and show the passing run.
- Test behavior seen from outside the object, never its structure.
- At least 1 test per new capability goes through the production construction path, with
  no injected double.
- Delete tests that only helped during development.
- A test that fails in the suite and passes alone is a defect. Never re-run hoping for
  green.

## Commit messages

- Say what changed in the code, in the repo's own vocabulary and message style.
- Never mention plan cards, card ids, step numbers, or plan names. The message must make
  sense to a reader who has never seen the plan.

## Short outputs

Commit messages, hand-backs, and summaries: no em dashes, digits for numbers, plain words.
