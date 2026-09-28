# Design principles and review checklist

The repo `CLAUDE.md` wins where it disagrees with this file.

## Design principles

- **SOLID.** One reason to change per class or module. Depend on interfaces, in the
  direction of stability.
- **DRY.** One home for each rule or fact. Two copies that change for different reasons
  are not duplication.
- **YAGNI.** Build what a current caller needs. No hooks, flags, or layers for a future
  that has no card.
- **Composition over inheritance.** Inherit only for a true "is a" with shared behavior.
- **Existing gem or crate first.** New code must beat a maintained library on a stated
  ground: size, licence, performance, or fit.
- **Immutable by default.** Mutate only where performance or architecture calls for it,
  and keep the mutation in one place.
- **Functional core, imperative shell.** Decisions live in pure functions. I/O, time,
  randomness, and state live at the edge.
- **Declarative over imperative** where the language has an idiom for it.

Before adding code, look for a refactor or a deletion that makes the change smaller.

## Review checklist

Check each item. Report only what you find.

- **Architecture.** A principle above is broken, or a known anti-pattern is present.
- **Dead code and dead tests.** Nothing calls it, or the test can no longer fail.
- **Redundant tests.** Two tests pin the same behavior. Tests left over from development
  that no longer protect anything.
- **Duplication** of logic, behavior, or function.
- **Non-idiomatic code** for the language or the repo.
- **Data integrity.** Partial writes, missing constraints, lossy conversions, silent
  truncation.
- **Concurrency.** Races, lock order, shared mutable state, work that assumes 1 process.
- **Comments.** Any comment that says WHAT the code does, or adds nothing. See
  `coding.md`.
- **Ambiguity.** Requirements or names that contradict each other or can be read 2 ways.
- **Reachability.** New behavior is constructed on the production path, not only in
  tests.
- **Simplification.** A smaller design gives the same behavior.
