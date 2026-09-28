# Task card

One card per implementing agent. Every field is required.

````markdown
### T<id>: <imperative title>          [risk: low|medium|high]

**Depends on:** T<ids> | none
**Files:** <exact paths to create or modify>
**Reuse:** <existing code to build on, by path or name>
**Shared-file wiring:** <1-line diffs for the main session to apply> | none
**Reachable from:** <the production site that constructs this work, e.g.
"CLI::Wiring#build -> Switchboard.for"> | deferred: <reason, also listed in Open
decisions>

**Acceptance criteria**

```gherkin
Scenario: <behavior>
  Given <state>
  When <action>
  Then <outcome seen from outside>
```
Spec file: `spec/.../<name>_spec.rb`

**Interface** (when the card adds or changes one)

```ruby
# signature only
```

**Stop and report if:**
- <a surprise specific to this card>
````

## Rules

- 1 card, 1 agent, 1 responsibility. If the title needs "and", split the card.
- Criteria describe behavior seen from outside the object. The implementer turns them
  into failing tests first, in the spec files the card names.
- At least 1 criterion per capability runs through the production construction path,
  with no injected double.
- `Reachable from` names the site that calls the constructor and passes the
  collaborator. A require line does not count, and neither does a keyword argument with
  a null default.
- Stop conditions name the exact spec, invariant, or file that could contradict the
  card. "If tests fail" is not a stop condition.
- Risk sets review depth and model choice. High: data, concurrency, security, or a
  public interface.
- Split a card whose sketch would break the repo's complexity limits.
- The same guard or conditional in 2 cards becomes its own card, ordered before both.
- If 2 cards need the same file, merge them or order them with `Depends on`.
- If the repo's hooks stash unstaged changes, each spec must load alone. Check the repo
  `CLAUDE.md`.
