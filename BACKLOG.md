# Backlog or Bugs

When complete, mark each off and include a sentence as to disposition.

- [ ] **Publish order matters.** `pubspec.yaml` requires `id_pair_set: ^2.0.0`,
  which is not on pub.dev yet, so `dart pub get` — and therefore the whole CI
  job — fails until that package is published. Locally this repo carries an
  untracked `pubspec_overrides.yaml` pointing at the working copy, so every gate
  runs; the override is deliberately not committed (pub ignores overrides in a
  dependency, so a consumer never sees it). Publish `id_pair_set` 2.0.0, then
  `dart pub publish` here.

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
