# Writing a finding

1 file per round. It is read twice: once by whoever writes the fix plan, and once by the
next round deciding what to re-check. It carries evidence, never narrative.

## Shape

Lead with a summary the reader can act on without scrolling:

```markdown
# QA round <N>, <date>

## Summary

<1 paragraph: what was confirmed fixed, what is new, what could not be reached>

| id | sev | what |
|---|---|---|
| **F21** | **HIGH** | the iteration ceiling is per session, so every chat dies silently after 25 calls |
| F17 | MED | the timeline view freezes after the first ask and never updates |

## Round <N-1> defects re-checked

| id | verdict | evidence |
|---|---|---|
| F8 | FIXED | `--limit 999999` refuses at construction naming flag, value, and max; exit 1 |

## Coverage

| scenario | driven | reason if not |
|---|---|---|
```

Then 1 section per finding, then third-party behaviour, then process notes.

## A finding

6 things. The middle 2 make it usable:

1. **An id and a severity.** HIGH: session-killer, data loss, or a silent wrong answer.
   MEDIUM: a real defect with a workaround. LOW: cosmetic but wrong.
2. **1 sentence of what is wrong**, in the codebase's own vocabulary.
3. **The mechanism**, at a file and line where you have one. "`seed_state` is called
   from `initialize`, so the counter never resets", never "the counter seems to
   persist".
4. **The evidence that rules out the nearest innocent explanation.** "Not the drain
   thread dying: the request view updates live on the same path" is worth more than 3
   paragraphs of description.
5. **A reproduction** someone else can run, with the commands.
6. **A fix shape**, if one is obvious, and what would pin it. The fix lands as a card
   with acceptance criteria.

## 3 categories, all worth filing

- **Defect**: it does the wrong thing.
- **UX finding**: it does the right thing obtusely. A refusal delivered as a traceback,
  a view with no placeholder while every sibling has one, a message that contradicts
  the screen beside it. A repeated shape becomes visible only once 3 are written down
  together.
- **Feature gap**: the round reached for something that does not exist. Say what you
  reached for.

Keep **third-party behaviour** (the model, a library, the OS) in its own section, so the
next round does not re-derive it. File it as an upstream bug only with a clean
reproduction that isolates the trigger.

## Rules

- Withdraw findings in the file. If the mechanism disproved something you nearly filed,
  that line stops the next round re-filing it.
- Never write "could not reproduce" as a pass. Write inconclusive, and say what would
  settle it.
- Say what you could not reach, and why. A path missed by 2 consecutive rounds is a
  finding about the plan.
- Cross-check every number against a second reader before quoting it. When the record,
  the state file, and the screen agree, say so. Agreement across 3 readers is a result.
- No secret values, ever. A value pasted into evidence outlives the transcript.
