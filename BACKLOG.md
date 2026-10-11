# Backlog or Bugs

When complete, mark each off and include a sentence as to disposition.

## Open

- [ ] **Strict atomicity across a failing write is best-effort.** The check pass
  completes before any write, and a failed write undoes the ones already made,
  but the undo is itself storage work that can fail. A transactional storage
  adapter would make this exact.
- [ ] **Consider dropping auto-increment.** Integer generation is only correct
  where one writer owns the namespace, which is rarely true of an id type a
  registry is guarding. UUID v4 needs none of the counter machinery. Decide
  whether the feature earns its surface before 3.0.0.
- [ ] **No consumers yet.** Nothing in the estate imports this package yet; it is
  a library waiting for its first caller.
- [ ] **Doc nit: broken dartdoc reference in the repository contract.** Stray
  backticks split the `[idType]`/`[idCode]` reference so dartdoc cannot resolve
  them. Cosmetic; no gate catches it.

## Deviations from the dart-flutter-bible — flagged for review

- [ ] **Barrel doc comment omits the error-style declaration.** §4 requires it in
  the barrel, README, and (on deviation) AGENTS.md; the README declares it, the
  barrel does not.
- [ ] **Barrel re-exports two whole third-party packages** (fpdart, id_pair_set).
  §2 wants one export line per public class; re-exporting pulls their full
  surfaces into this package's contract. Deliberate, but divergent.
- [ ] **Barrel exports data-layer implementation classes.** §3 puts adapter
  wiring in the composition root, not the package contract; a pure library may
  need a way to expose one. Flagged for review.
- [ ] **No `AGENTS.md`.** §1/§11 make it the single in-repo place to record this
  repo's deviations; none exists, so the audit trail lives only here.
- [ ] **No `dart_arch_test` architecture test.** §2/§9 make it CI's hard gate;
  nothing checks that `domain/` never imports `data/`. Single-package layout
  makes the split hard to express.
- [ ] **No write method takes an optional `IUnitOfWork?`.** §5 wants the uniform
  transaction seam; atomicity is the registry's own best-effort undo instead.
- [ ] **`register`/`unregister` take an `IdPairSet` container.** §4 bans container
  objects at the seam; it is a domain value object, so the rule may not apply.
  Flagged for review.
- [ ] **Contract names omit the `I` prefix** the bible uses throughout; `IdStorage`
  is also not named as a datasource. Naming only.
- [ ] **No application/use-case layer.** §3 puts the use case in the facade
  position; here the repository contract is the public seam. May be the honest
  reading for a pure library.
- [ ] **`equatable` absent.** §4 makes it standard for entities/value objects; the
  2.0.0 changelog argues there are none left. Consistent on its own terms; flagged.
- [ ] **`getOrElse` callbacks take zero arguments in tests.** §6 says the callback
  receives the `Left`; both forms compile, which makes it silent style drift. The
  shared contract suite already uses `(_) =>`.
- [ ] **`analysis_options.yaml` is not strict.** §9 asks for a strict root with
  `strict-casts`/`strict-raw-types`; only `recommended` plus two extras are set.
  A floor question, not a defect.
