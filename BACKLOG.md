# Backlog or Bugs

When complete, mark each off and include a sentence as to disposition.

- [x] **Publish order matters.** `pubspec.yaml` requires `id_pair_set: ^2.0.0`,
  which is not on pub.dev yet, so `dart pub get` — and therefore the whole CI
  job — fails until that package is published. Locally this repo carries an
  untracked `pubspec_overrides.yaml` pointing at the working copy, so every gate
  runs; the override is deliberately not committed (pub ignores overrides in a
  dependency, so a consumer never sees it). Publish `id_pair_set` 2.0.0, then
  `dart pub publish` here.
  - **Disposition (2026-09-24):** done. `id_pair_set` 2.0.0 is on pub.dev now,
    so `dart pub get` resolves it hosted (`source: hosted`,
    `url: "https://pub.dev"` in `pubspec.lock`) with no override present — the
    `pubspec_overrides.yaml` this note describes no longer exists and is not
    needed.

- [ ] **Strict atomicity across a failing write is best-effort.** The check pass
  is complete before any write, and a failed write undoes the ones already made,
  but the undo is itself storage work that can fail. A storage adapter that
  supports transactions could make this exact; today only the in-memory adapter
  is genuinely atomic.

- [ ] **Consider dropping auto-increment.** Integer generation is only correct
  where one writer owns the namespace, which is rarely true of an id type a
  registry is guarding. UUID v4 needs none of the counter machinery. Decide
  whether the feature earns its surface before 3.0.0.

- [ ] **No consumers yet.** Nothing in the estate imports this package. Its
  honest use case is a store of things that must not share identifiers (a
  library scanner's ISBNs, a catalog's part numbers); until one exists, treat it
  as a library waiting for its first caller.

- [ ] **`memory-bank/` was removed** in the 2.0.0 rework: it described the
  pre-2.0.0 architecture and would have been a second, stale truth.

## Windows-lane audit — 2026-09-24

Every gate was run on the Windows lane (Dart SDK 3.13.1). All of them pass with
real output; the items below are the problems and deviations the audit turned up
that are *not* build failures.

- **Gates, all green:** `dart pub get` (resolved, no override needed);
  `dart format --output=none --set-exit-if-changed .` → "Formatted 22 files
  (0 changed)"; `dart analyze --fatal-infos --fatal-warnings` → "No issues
  found!"; `dart test` → "All tests passed!" (40 tests); `dart run
  example/main.dart` → runs clean; `dart pub publish --dry-run` → "Package has
  0 warnings."

- [ ] **Doc nit: broken dartdoc reference in the repository contract.**
  `lib/src/domain/repositories/id_registry_repository.dart` documents
  `isRegistered` as ``Whether [idType]`:[idCode] is already registered.`` — the
  stray backticks split the reference so dartdoc cannot resolve
  `[idType]`/`[idCode]` cleanly. Cosmetic; no gate catches it.

- [ ] **Dependency currency.** `dart pub outdated` (2026-09-24): direct
  dependencies all up to date; `melos` 8.8.0 → 8.9.0 *resolvable* (`^8.8.0`
  permits it, so this is a choice not a fault); `equatable` 2.1.0 vs 3.0.0 and
  `platform` 3.1.6 vs 3.2.0/`cli_launcher` 0.3.3+2 vs 0.3.4 are transitive
  pinning, not this package's call. Nothing here is broken; recorded so the next
  pass does not re-derive it.

- [ ] **No `pubspec_overrides.yaml` in the tree, and none needed.** The item
  above used to depend on an untracked override; it is gone (as designed) and
  `dart pub get` is clean without it. Kept as a note so nobody re-adds one
  thinking it is still required.

### Deviations from the dart-flutter-bible — flagged for review, not auto-fixed

Compared against `staylorx/dart-flutter-bible` `docs/` (§1–§12). A deviation is a
place this package differs from the bible; the bible may itself be wrong, so each
is flagged for a later decision rather than patched here.

- [ ] Deviation: `lib/id_registry.dart` — the barrel's doc comment does not
  declare the package's error style. §4 "Declare the error style, loudly"
  requires the declaration in *three* places: the barrel doc comment, the
  README, and (on deviation from the `Future<Either>` default) `AGENTS.md`. The
  README declares it ("Failures are values"), the barrel says only what the
  package is. This package follows the default, so `AGENTS.md` is not owed — but
  the barrel half of the rule is unmet.

- [ ] Deviation: `lib/id_registry.dart` — the barrel re-exports two whole
  third-party packages (`export 'package:fpdart/fpdart.dart'`,
  `export 'package:id_pair_set/id_pair_set.dart'`). §2 "Barrel files": a barrel
  is hand-maintained, "one export line per public class", and "what's exported
  *is* the public API". Re-exporting a dependency's entire surface imports
  fpdart's and id_pair_set's public API into this package's contract, so a
  breaking change upstream becomes a breaking change here. Deliberate (it is how
  a consumer gets `Either`/`IdPairSet` without a second dependency), but it
  diverges from the one-line-per-class rule.

- [ ] Deviation: `lib/id_registry.dart` — the barrel exports data-layer
  implementation classes (`IdRegistryRepositoryImpl`, `FileBasedIdStorage`,
  `InMemoryIdStorage`, `CachedIdStorage`). §3 Topology puts adapter wiring in the
  *composition root* (the app/CLI), not the package contract; §1 "Nothing
  outside knows anything concrete about the center". A pure library with no
  composition root has to expose *some* way to build one, so this may be the
  faithful reading — flag for review.

- [ ] Deviation: repo root — there is no `AGENTS.md`. §1 D.R.Y. and §11 make
  `AGENTS.md` the one place a repo records its *own* deviations and local wiring
  (the doctrine stays in the bible). This repo has deviations (this section) but
  no in-repo place for them, so the audit trail lives only in `BACKLOG.md`.

- [ ] Deviation: repo root — there is no `dart_arch_test` architecture test.
  §2/§9 step 7 make it CI's hard gate: package-boundary direction over the
  resolved import graph plus workspace-wide cycle-freedom, running as part of
  `dart test`. This package is a single package, so `package:` URIs cannot
  express the domain/data split, and nothing checks that `domain/` never imports
  `data/`. Direction is currently convention only.

- [ ] Deviation: `lib/src/domain/repositories/id_registry_repository.dart`,
  `lib/src/domain/datasources/id_storage.dart` — no write method takes an
  optional `IUnitOfWork? uow`. §5 Persistence: "write methods take optional
  `IUnitOfWork? uow` … the contract still declares `uow`, so the seam is
  uniform". Here atomicity is the registry's own best-effort undo (see the
  atomicity item above) rather than a declared, adapter-supplied transaction
  seam.

- [ ] Deviation: `lib/src/domain/repositories/id_registry_repository.dart` —
  `register`/`unregister` take an `IdPairSet<IdPair<Object>>` container. §4 "Use
  case parameters: business params, not cargo" bans container objects at the
  usecase/repository seam. `IdPairSet` is a cohesive domain *value object* from
  `id_pair_set`, not an anonymous bag, so the rule may not apply — but it reads
  as a cargo object and the bible does not carve out domain value objects
  explicitly. Flag for review.

- [ ] Deviation: `lib/src/domain/datasources/id_storage.dart`,
  `lib/src/domain/repositories/id_registry_repository.dart` — contract names
  omit the `I` prefix the bible uses throughout (`IAccountRepository`,
  `IAccountDatasource`). `IdStorage` is also not named as a *datasource*
  (`IdRegistryDatasource`, or similar). Naming only; no gate exists for it.

- [ ] Deviation: repo root — there is no application/use-case layer. §3 "the
  application layer (use cases) **is** the shared public face of the core"; here
  the repository contract is the public seam and consumers call it directly. For
  a pure library with one delivery shape this may be the honest reading (no
  orchestration is being hidden), but it does put the repository — not a use
  case — in the bull's-eye's facade position.

- [ ] Deviation: `pubspec.yaml` — `equatable` is absent. §4 "Equality:
  equatable" and the §Stack pin make `equatable` the standard for entities
  and value objects; the 2.0.0 CHANGELOG argues the package has no value objects
  ("nothing in the package is a value object any more"), so there is nothing to
  give value semantics to. Consistent on its own terms; flagged because the
  doctrine states the rule unconditionally.

- [ ] Deviation: `test/id_registry_test.dart` — several `getOrElse` callbacks
  are written with **zero** arguments (`getOrElse(() => fail('expected a Left'))`,
  also `(() => false)`, `(() => <String>{})`, `(() => true)`), where §6 states
  the callback receives the `Left` value: write `getOrElse((_) => …)`, never
  `getOrElse(() => …)`. Both forms compile (Dart allows a function with fewer
  positional params), which is exactly what makes it a silent style drift. The
  shared contract suite (`test/support/id_storage_contract.dart`) already uses
  the correct `(_) =>` form throughout.

- [ ] Deviation: `analysis_options.yaml` — only `package:lints/recommended.yaml`
  plus `public_member_api_docs` and `todo: error`. §9 step 8 asks for a *strict*
  root `analysis_options.yaml`; there are no `strict-casts`/`strict-raw-types`
  language settings and no extra strictness beyond the recommended set. All
  gates are clean at this setting, so this is a floor question, not a defect.
