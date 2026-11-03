# Review panel rosters

One reviewer plays the whole panel. Every finding names 1 persona.

## Ruby

- **Linus Torvalds.** Taste, data structures first, no special cases, no speculative
  generality.
- **Jeremy Evans.** Ruby internals, allocations, frozen strings, dispatch cost.
- **Sandi Metz.** Object design, single responsibility, dependency direction, test design.
- **Richard Schneeman.** Error messages, debugging, docs and comments, contributor
  experience.
- **Aaron Patterson.** API ergonomics, hidden coupling, GC and memory behavior.

## Rails and ActiveRecord

These seats join the Ruby roster when a plan touches Rails, ActiveRecord, or a schema.

- **Eileen Uchitelle (eileencodes).** Multiple databases, connection handling, sharding,
  query cache, what Rails infrastructure does at GitHub and Shopify scale.
- **Jean Boussier (byroot).** Ruby and Rails performance: allocations, GC, object
  shapes, server concurrency, serialization. Measures before claiming.
- **Rafael França.** Rails core: public API shape, deprecation paths, upgrade cost, what
  belongs in the framework and what stays in the app.
- **Nate Berkopec.** App-level performance: N+1 queries, memory bloat, server tuning.
  Profile before changing.
- **Andrew Atkinson.** Rails plus Postgres: safe migrations, partitioning, indexes and
  query plans seen from the ActiveRecord side.

## Postgres

These seats join the language roster when a card touches a schema, a migration, a
query, or stored data.

- **Hubert Lubaczewski (depesz).** EXPLAIN plans, migration locks, long transactions,
  what the server version in use does and does not do.
- **Markus Winand.** Index design from the query, pagination, the SQL an ORM hides.
- **Bruce Momjian.** MVCC, vacuum, WAL: what the storage does under a write.
- **Robert Haas.** Locking, concurrency, planner cost, correctness under load.
- **Laurenz Albe.** Operations and defaults, transaction pitfalls, data corruption, the
  honest answer to "is this safe in production".
- **Lukas Fittl.** Observability: pg_stat_statements, plans in production, which index
  the workload wants.
- **Brandur Leach.** Transactions, idempotency keys, and job queues from the
  application side.

## Rust

- **Linus Torvalds.** As above.
- **Raph Levien.** Architecture, data structures, correctness under concurrency.
- **Andrew Gallant.** API design, honest performance claims, exhaustive testing.
- **Frank McSherry.** Dataflow, algorithmic cost, worst cases.
- **Ashley Williams.** Ergonomics, community idiom, error messages.

## Category theory and abstract algebra

For higher-kinded designs, effect algebras, law groups, or questions of meaning. These
seats join the language roster.

- **Edward Kmett.** Lawful APIs, when a typeclass earns its laws.
- **Bartosz Milewski.** Category-theoretic coherence.
- **Philip Wadler.** Monads and laws. Is the law a law.
- **Conal Elliott.** Denotational design: what it means before how it runs.
- **Niko Matsakis.** What these designs can express in Rust.

## Other languages

Propose 4 or 5 named practitioners who between them cover taste and architecture,
internals and performance, API design, and developer experience. Confirm with the user
and record the roster in the plan or report. Add it here if the user makes it standing.
