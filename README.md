# id_registry

Uniqueness and id generation across many collections of identifiers.
`id_pair_set` says what ids one thing has; `id_registry` says which ids are
already taken, in a form every collection you own can check against.

## Why

Identifiers only do their job if they are unique across the whole store, not
just inside one record. An ISBN registered to one book must not be registrable
to another, and a code minted for a new thing must not collide with one that
already exists. That is a property of the collection of collections, so it needs
a home outside any single record — that home is this package.

## What it does

- **Registers sets**: `register` takes an `IdPairSet` and checks every id
  against every id registered before. It is **atomic** — every id in the set is
  validated and checked before any of them is written, and a write that fails
  part way through is undone — so a refused registration leaves the registry
  exactly as it was.
- **Unregisters sets**, freeing the ids for reuse.
- **Validators**: attach an `IdValidator` (ISBN-10, ISBN-13, ORCID, or your
  own) to an id type and registration enforces the format.
- **Generators**: attach `IdGeneratorType.autoIncrement` or `.uuid` to an id
  type and `generateId` mints a free id and registers it before returning it.
- **Pluggable storage**: `InMemoryIdStorage`, `FileBasedIdStorage` (one JSON
  file, written through on every mutation) and `CachedIdStorage` (a decorator
  over either). All three run the same contract suite, so swapping them changes
  nothing a caller sees.

## Failures are values

Every method answers with `Either<IdRegistryFailure, …>`: a duplicate, a code
that fails its validator, a missing generator or an unwritable store comes back
as a `Left` you can switch on — never as a thrown exception, and never as a
half-finished operation. `IdRegistryFailure` is a sealed hierarchy, so a switch
over it is exhaustive.

## Concurrency

Mutating calls — `register`, `unregister`, `generateId`, `clear` — run one at a
time inside the registry. Check-then-write is not atomic on its own: two
registrations of the same id would otherwise both pass the check pass, and two
generation calls would otherwise mint the same integer.

## Usage

`example/main.dart` is the runnable tour (CI runs it on every push), and `test/`
is the reference for every behaviour above — including the atomicity and
concurrency guarantees.

Add `id_registry: ^2.0.0` to your pubspec.

## Upgrading from 1.x

2.0.0 turned thrown exceptions into returned failures: `register`,
`unregister`, `generateId` and `clear` answer with `Either`, `IdRegistry` became
`IdRegistryRepositoryImpl`, and `IdStorage` methods now return `Either` too. The
2.0.0 section of [CHANGELOG.md](CHANGELOG.md) has the full list.

## Related

`id_pair_set` — the identifiers this registry makes unique.

## License

MIT. See [LICENSE](LICENSE).
