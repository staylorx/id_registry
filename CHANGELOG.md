## Unreleased

### Changed
- **The local publish override is gone.** `id_pair_set` 2.0.0 is on pub.dev, so
  `dart pub get` now resolves it hosted and the untracked
  `pubspec_overrides.yaml` the 2.0.0 notes relied on is neither present nor
  needed. This closes the "Publish order matters" backlog item, which is marked
  off with its disposition.

### Added
- **Windows-lane audit of every gate** (Dart SDK 3.13.1): `dart pub get`,
  `dart format --output=none --set-exit-if-changed`, `dart analyze
  --fatal-infos --fatal-warnings`, `dart test` (40 tests), the CI example, and
  `dart pub publish --dry-run` (0 warnings) all pass. The findings and the
  deviations from `dart-flutter-bible` flagged for review are recorded in
  `BACKLOG.md`. No source was changed by this pass.

## 2.0.0 - 2026-09-19

Rebuilt around the two guarantees a registry exists to provide: a refused
registration changes nothing, and two callers never get the same id.

### Changed
- **Failures are values.** `register`, `unregister`, `generateId` and `clear`
  answer with `Either<IdRegistryFailure, …>` instead of throwing
  (`fpdart` ^1.2.0). `DuplicateIdException` and `ValidationException` are gone.
- **`register` is atomic.** Every id is validated and checked before any is
  written, and a failed write undoes what was written, so a refusal leaves the
  registry untouched. Previously the set was written id by id and the throw
  landed mid-loop, leaving a half-registered batch.
- **Mutating calls are serialised.** Two concurrent `generateId` calls used to
  compute the same next integer and hand out the same id; two concurrent
  registrations could both pass the check pass.
- **Auto-increment uses the stored counter** instead of re-reading every code
  on every mint, seeded from the highest existing numeric code so a registry
  restored from storage resumes rather than colliding. The counter API is now
  live rather than dead weight, and the probe still skips existing codes, so a
  lost counter can waste an id but cannot produce a duplicate.
- **`clear()` is symmetric**: registrations, validators, generators and
  counters all go. Previously validators were dropped while generators stayed.
- **Storage contracts answer with `Either`**, and the file-backed store writes
  through on every mutation before reporting success.
- `IdStorage` takes discrete `idType`/`idCode` parameters.
- SDK constraint is now `>=3.10.0 <4.0.0`; `equatable` dropped (nothing in the
  package is a value object any more).

### Added
- `IdRegistryFailure` and `IdStorageFailure`, sealed hierarchies per layer, with
  a repository that maps storage failures upward.
- `codesFor` and `idTypes` on the repository, and `counterFor`/`setCounter` as
  first-class storage operations.
- `CachedIdStorage`, and a shared storage contract suite run against all three
  adapters.
- CI: format, `dart analyze --fatal-infos --fatal-warnings`, tests, the example,
  and a publish dry-run.

### Removed
- `IdRegistry` (renamed `IdRegistryRepositoryImpl`), `DuplicateIdException`,
  `ValidationException`, and `IdValidators` (the static helpers — use
  `IsbnIdValidator`, `Isbn13IdValidator`, `OrcidIdValidator`).
- `IdStorage.getCounter`/`setCounter` are no longer dead API: they are
  `counterFor`/`setCounter` and the generator uses them.

## 1.0.1 - 2025-12-30

### Added
- Doc comments throughout.

## 1.0.0 - 2025-12-30

### Added
- `IdRegistry` for global uniqueness across `IdPairSet`s, throwing
  `DuplicateIdException` on conflict.
- Validators (`IdValidators`, `OrcidIdValidator`, `IsbnIdValidator`,
  `Isbn13IdValidator`), `IdGeneratorType` (auto-increment, uuid), and
  in-memory, file-based and caching storage.
