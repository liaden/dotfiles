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

## Naming

Classes, modules, methods, arguments, and variables each get a name that says what
that thing is or does in this code.

- **Specific.** Name the domain thing: `overdue_invoices`, `retry_delay`. Generic names
  (`data`, `result`, `items`, `info`, `obj`, `val`, `tmp`, `thing`) say nothing.
- **No boilerplate.** Cut words that carry no meaning: `Manager`, `Helper`, `Util`,
  `Handler`, `Processor`, `Base`, `Impl`; verbs like `handle_`, `process_`, `do_`,
  `perform_`; type suffixes like `_str`, `_hash`, `_list`; a prefix that repeats the
  enclosing name (`User#user_email`). Keep a word the framework or repo convention
  requires.
- **True to the code.** A method name says what it returns or what it changes. A
  predicate reads as a question. A name that promises more, less, or something else
  than the body does is a bug waiting for a caller.
- **Consistent.** 1 concept, 1 word, across the change and the code around it.
- **Plural for many, singular for 1.** A collection is plural (`invoices`), an element
  is singular (`invoice`), a count ends `_count`, a lookup hash says its key
  (`invoices_by_customer`). A plural name on a single value, or a singular on a list,
  is a finding.
- **Ruby idiom.** Predicates end `?` with no `is_` or `has_` prefix. A `!` method has a
  safe twin or raises where the twin returns nil. Readers and writers are `name` and
  `name=`, never `get_name` or `set_name`. Conversions are `to_x`; constructors from
  another type are `from_x` or `X()`. Constants are `SCREAMING_SNAKE_CASE`.
- **Rails convention.** Models are singular and tables plural; controllers are plural
  (`InvoicesController`). `has_many` names are plural, `belongs_to` and `has_one`
  singular. Foreign keys are `<association>_id`. Boolean columns read as adjectives
  (`archived`, not `is_archived`). Datetime columns end `_at`, date columns `_on`.
  Scopes read as filters on the plural (`Invoice.overdue`). Concerns read as
  adjectives (`Archivable`). Suffixes Rails expects, such as `Job`, `Mailer`, and
  `Controller`, stay.
- **Length follows scope.** Short names are fine in a 3 line block and for idioms such
  as `i`, `e`, `k, v`, `it`.

When a name falls short, propose 2 to 4 candidates. Build them from:

1. What it does: the verbs and nouns the body acts on.
2. How it is used: every caller and reader. The call site should read as a phrase.
3. The repo's vocabulary: words its code, schema, and docs already use for this idea.
4. Synonyms: weigh near synonyms for the right shade, such as `find` (may be nil)
   against `fetch` (raises) against `load` (does I/O), or `remove` against `delete`
   against `discard`.

Rank the candidates and give 1 line on why the first beats the rest.

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
- **Naming.** A name under review is generic, carries boilerplate, or
  does not match what the code does. See Naming above. A misleading name is
  SHOULD-FIX; a generic or padded one is a NIT unless it is public API.
- **Ambiguity.** Requirements or names that contradict each other or can be read 2 ways.
- **Reachability.** New behavior is constructed on the production path, not only in
  tests.
- **Simplification.** A smaller design gives the same behavior.
