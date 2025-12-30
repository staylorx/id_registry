## \[1.0.1] - 2025-12-30

### Changed

Exported id\_pair\_set also for downstream folks who use it.

## \[1.0.0] - 2025-12-30

Split from id\_pair\_set.

### Added

* `IdRegistry` class for managing global uniqueness of ID pairs across multiple `IdPairSet` instances.
* `DuplicateIdException` for handling conflicts when registering duplicate IDs.
* New clean architecture example demonstrating advanced usage.

### Changed

* Updated documentation and examples for better clarity.
