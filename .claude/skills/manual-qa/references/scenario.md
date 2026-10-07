# Scenario

1 file per question, `planning/qa/scenarios/<slug>.md`. A scenario answers 1 question
about the real app that the suite cannot.

## Shape

```markdown
# Scenario: <title>

**Why this one exists:** <the question, and what the suite cannot see>

**Cost:** <cheap | minutes | sessions | quota>. **Needs:** <every precondition: a
service up, a tool on PATH, a variable set, a seeded project. "nothing running" is a
valid answer>

---

## 1. <step title>

<1 action per line, with the expected outcome as a constant where there is one>

**Automated by** `<spec path>`, "<example name>": <what it pins>. **Still needs a
human:** <what the spec cannot see>.
```

## Rules

- Expected outcomes are constants where possible: a refusal string, a number, a file
  that must not exist. A model's answer is never an expected outcome.
- Cheap deterministic sections come first. If a constant is already wrong, the
  expensive steps are wasted.
- A section the suite now drives keeps an `Automated by` line and its human half.
  Delete the section only when nothing in it needs a human.
- Counts and rosters go stale. Say where to re-derive them (the registry, the help
  output, the directory) rather than writing the number.
- `Needs:` states what the round must provide, so "not reached" can be checked against
  it.

## README

`planning/qa/README.md` lists every scenario with the question it answers and its cost,
in the order to drive them, and names what to cut first when a scoped round will not
fit. It holds no count.

## method.md

Scenario-independent, read once per round: toolchain, bring-up, isolation and how to
prove it, how to drive the app and read its record, what to record per act, known traps,
and third-party failure modes. Each round appends what it taught the process.
