# Plan lint

Run every check on the draft and fix failures before the panel or the user sees it.

Cards:
- [ ] Every card has an id, an imperative title, a risk, and all fields from
      `task-card.md`
- [ ] Every criterion maps to a named spec file and describes behavior, not structure
- [ ] Files and Reuse use exact paths
- [ ] Stop conditions are specific to the card
- [ ] New or changed interfaces have a code snippet

Graph:
- [ ] The mermaid dependency graph matches every card's `Depends on`
- [ ] The graph has no cycle
- [ ] No 2 cards that can run at the same time share a file
- [ ] No card lists a shared file under Files
- [ ] No card depends on an item in Open decisions

Reachability:
- [ ] Every capability has a card whose `Reachable from` names a production
      construction site, or says "deferred" with a reason that also appears in Open
      decisions. Every behavior promised in Intent is covered by some criterion

Document:
- [ ] commit-mode, language, and panel are set
- [ ] Grounding has a date, a SHA, and the files checked
- [ ] Compatibility has a verdict and evidence for every surface the plan touches
- [ ] Every spike has a question, a result, and evidence, and its worktree is gone
- [ ] Integration checks are present, including any manual pass
- [ ] No em dashes. Digits for numbers
