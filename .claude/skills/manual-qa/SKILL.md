---
name: manual-qa
description: Drive a manual QA round against the real app from the scenarios in the repo's planning/qa/. With no scope named it runs every scenario. Use when asked to run manual QA, run a QA round, verify fixes end to end, or exercise happy and unhappy paths against the real binary.
argument-hint: [scenario or section]
---

# Manual QA

You drive the round yourself against the real app. Where the app puts a human in the
loop (an approval, a confirmation, a choice), you are that human, and that step is under
test.

The suite is green. You are looking for 2 real components disagreeing, and for the
moments a human would be misled.

## Inputs

The repo owns the method; this skill owns the procedure.

| File | Holds |
|---|---|
| `planning/qa/README.md` | the scenario roster, its order, and what to cut first |
| `planning/qa/method.md` | bring-up, isolation, how to drive the app, what to record, known traps |
| `planning/qa/scenarios/*.md` | 1 question each, per `references/scenario.md` |

If the repo keeps these elsewhere, its `CLAUDE.md` says where. If the repo has its own
`.claude/skills/manual-qa/SKILL.md`, read it too. It wins on anything app-specific.

If none exist, this is the first round. Write the README, `method.md`, and the first
scenarios with the user, per `references/scenario.md`, before driving anything. A round
with no scenario is exploration, and the findings say so.

## 1. Scope

- `ls planning/qa/scenarios/`. That listing is the set. Never a remembered list, a
  count, or a roster written in any document.
- No scope named: drive every scenario. README's tiers set order and budget, never a
  filter.
- A scenario README does not place: drive it, and say so.
- Scope named: drive it whole, including sections automation covers.
- Dropping a scenario is a decision you name in the findings, with the reason.
- A section marked `Automated by` is skipped in a full round. Drive its `Still needs a
  human` half, and say in the coverage table that you relied on the automation.
- State the plan in 2 lines with its cost, and start. Do not block on the question.

## 2. Bring up and prove isolation

Follow `method.md`. Before act 1:

- Record the start time and a `git status --porcelain` baseline. Neither can be
  reconstructed later.
- Prove the sandbox: every process under test shows the redirected state paths, per
  `references/isolation.md`. A gate that fails stops the round. Never work around it.
- Check the box is quiet: `uptime`, and nothing left over from earlier agent work.

## 3. Drive

Follow each scenario's own steps, in the order step 1 settled. A scenario that brings
up its own subject gets that bring-up in this round. Never interleave 2 bring-ups.

- Send an input once, then poll the app's record. Never retry on the screen.
- Read the app's ground truth (journal, database, log), never the screen alone. Where
  they disagree, that is the finding.
- Never approve an action you have not read. An approval that renders nothing is itself
  a finding; record it, then recover.
- An input accepted and answered with nothing is a finding, never a known cost.
- Record per act what `method.md` names: the record, the state, and the screen at the
  moment of a finding.

## 4. Verify the mechanism before filing

- Reproduce it, then explain it. A finding needs a reproduction someone else can run.
- Read the code that produces the behaviour before naming a cause.
- Check whether the behaviour is documented scope. That makes it a UX finding.
- Prefer a measurement to an inference. A counter beats a suspicion.
- Re-measure every number and re-check every claim the documents give you, the
  method's own included. A recorded measurement is what 1 machine did once.
- When you overturn a claim, take the control: ask what observation would look the
  same if the claim were true, and go take it.
- Keep third-party findings (the model, a library, the OS) in their own section.

## 5. Write the findings

1 file, `planning/qa-findings-round<N>-<date>.md` or the repo's own location, per
`references/findings-format.md`.

- 3 categories: defect, UX finding, feature gap.
- Re-check every defect from the previous round and say whether different means
  better.
- A coverage table over the full listing: every scenario, what was driven, and the
  reason for anything not driven.
- "Not reached, needs X" is a claim. Check it first: read the scenario's `Needs:` line
  and test the variable with `[ -n "${X:-}" ]`. Never print a secret, into the
  transcript or the findings. Patience is a budget reason; state it as one.

## 6. Close out

- Kill everything the round started, by pid, and check the ports it used. Killing the
  terminal server reaches neither daemons nor listeners.
- Verify the negatives, each with a positive control beside it, per
  `references/isolation.md`.
- Leave the sandbox in place. It is evidence.
- Fold what the round taught the process into `method.md` or the scenario, and say you
  did.
- Summarize: confirmed fixed, new by severity, not reached and why.

## 3 rules that outrank the rest

1. A round that finds nothing new did not push hard enough.
2. A fix can make the failure worse. When a previous defect behaves differently, say
   whether differently means better.
3. Report faithfully. Skipped is skipped. Inconclusive is inconclusive, never "could
   not reproduce" written as a pass.
