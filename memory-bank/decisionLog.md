# Decision Log

This file records architectural and implementation decisions...

*
[2025-12-30 18:03:24] - Refactored IdStorage to follow Clean Architecture principles. Moved the abstract IdStorage interface to lib/src/domain/id_storage.dart (domain layer) and concrete implementations (InMemoryIdStorage and CachedIdStorage) to lib/src/data/ (data layer). Updated exports and imports accordingly. All tests pass.
