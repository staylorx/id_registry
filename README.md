# id_registry

[![pub package](https://img.shields.io/pub/v/id_registry.svg)](https://pub.dev/packages/id_registry)
[![License](https://img.shields.io/github/license/staylorx/id_registry)](https://github.com/staylorx/id_registry/blob/main/LICENSE)

A Dart package that provides a registry for enforcing global uniqueness of ID pairs across multiple IdPairSets. It builds on the [id_pair_set](https://pub.dev/packages/id_pair_set) package to manage sets of unique ID pairs and ensures no duplicates across all registered sets, making it ideal for applications requiring centralized ID management.

## Features

- **Global Uniqueness Enforcement**: Enforce uniqueness across multiple `IdPairSet` instances for specified idTypes, throwing exceptions on conflicts.
- **Validation Support**: Set custom validators for idTypes to ensure data integrity during registration.
- **Pluggable Storage**: Easily swap between in-memory, cached, or persistent storage implementations.
- **Immutable Operations**: Works seamlessly with immutable `IdPairSet` instances from the id_pair_set package.
- **Exception Handling**: Provides clear exceptions for duplicate or invalid IDs.
- **Built on id_pair_set**: Leverages the efficient and feature-rich `IdPairSet` data structure for managing unique ID pairs by type.

## Installation

Add `id_registry` to your `pubspec.yaml`:

```yaml
dependencies:
  id_registry: ^1.0.0
```

This will automatically include the `id_pair_set` dependency.

Then run:

```bash
dart pub get
```

Or if using Flutter:

```bash
flutter pub get
```

## Usage

The `id_registry` package is designed to work with `IdPairSet` from the `id_pair_set` package. First, ensure you have `IdPairSet` instances ready. For details on creating and managing `IdPairSet`, see the [id_pair_set documentation](https://pub.dev/packages/id_pair_set).

### Basic Usage

```dart
import 'package:id_registry/id_registry.dart';
import 'package:id_pair_set/id_pair_set.dart';

// Assume you have IdPairSet instances (from id_pair_set package)
final book1Ids = IdPairSet([
  MyIdPair('isbn', '978-3-16-148410-0'),
  MyIdPair('upc', '123456789012'),
]);

final book2Ids = IdPairSet([
  MyIdPair('isbn', '978-1-23-456789-0'),
  MyIdPair('ean', '1234567890123'),
]);

// Create a registry to enforce global uniqueness
final registry = IdRegistry();

// Register sets (throws DuplicateIdException if conflicts)
registry.register(book1Ids);
registry.register(book2Ids); // This would throw if ISBNs conflict

// Check registration
if (registry.isRegistered(idType: 'isbn', idCode: '978-3-16-148410-0')) {
  print('ISBN is registered');
}

// Unregister when needed
registry.unregister(book1Ids);
```

### Adding Validation

```dart
// Set a validator for ISBNs
registry.setValidator('isbn', (value) => value.startsWith('978'));

// Now registration will validate ISBNs
try {
  registry.register(IdPairSet([MyIdPair('isbn', 'invalid')])); // Throws ValidationException
} catch (e) {
  print('Validation failed: $e');
}
```

See the [clean architecture example](example/clean_architecture_example.dart) for a complete implementation, and the [custom validator example](example/custom_validator_example.dart) for implementing custom validators.

## API Overview

### IdRegistry

Manages global uniqueness across multiple `IdPairSet` instances for all idTypes.

**Constructor:**
- `IdRegistry({IdStorage? storage})`: Creates a registry with optional custom storage (defaults to in-memory).

**Methods:**
- `void register(IdPairSet set)`: Registers a set, throwing `DuplicateIdException` on conflicts or `ValidationException` if validation fails.
- `void unregister(IdPairSet set)`: Unregisters a set, removing its unique identifiers.
- `bool isRegistered({required String idType, required String idCode})`: Checks if an idType/idCode combination is registered.
- `Set<String> getRegisteredCodes({required String idType})`: Returns all registered codes for an idType.
- `void clear()`: Clears all registrations.
- `void setValidator(String idType, bool Function({required String value}) validator)`: Sets a validator function for an idType.
- `void setValidatorFromIdValidator(String idType, IdValidator validator)`: Sets a validator instance for an idType.

### IdValidator

Abstract base class for custom validators.

**Methods:**
- `bool validate({required String value})`: Validates the given value.

### Exceptions

- `DuplicateIdException`: Thrown when attempting to register a conflicting identifier.
- `ValidationException`: Thrown when an idCode fails validation.

### Storage Abstractions

The registry supports pluggable storage backends for flexibility in persistence and caching:

- `IdStorage`: Abstract interface defining storage operations (add, remove, contains, getAll, clear).
- `InMemoryIdStorage`: Default in-memory implementation using a Map.
- `CachedIdStorage`: Caching wrapper that can wrap any storage backend for improved performance.

**Example with caching:**

```dart
import 'package:id_registry/id_registry.dart';

// Use cached storage for better performance
final storage = CachedIdStorage(InMemoryIdStorage());
final registry = IdRegistry(storage: storage);

// Registry operations work the same way
registry.register(myIdSet);
```

This design allows future extensions to database, file-based, or other persistent storage systems.

## Comparison with id_pair_set

While `id_pair_set` provides immutable sets of unique ID pairs with operations like adding, removing, and filtering, `id_registry` extends this by enforcing global uniqueness across multiple sets. Use `id_pair_set` for local ID management and `id_registry` when you need centralized control over uniqueness in a larger system.

## Contributing

Contributions are welcome! Please see the [contributing guide](https://github.com/staylorx/id_registry/blob/main/CONTRIBUTING.md) for details.

## Git Hooks

This project uses [Husky](https://typicode.github.io/husky/) to manage Git hooks. The pre-commit hook automatically formats your Dart code using `dart format .` to ensure consistent code style before each commit.

## Issues and Feedback

If you find a bug or have a feature request, please file an issue on [GitHub](https://github.com/staylorx/id_registry/issues).

## Changelog

See the [CHANGELOG.md](https://github.com/staylorx/id_registry/blob/main/CHANGELOG.md) for recent changes.

## License

This package is licensed under the MIT License. See [LICENSE](https://github.com/staylorx/id_registry/blob/main/LICENSE) for details.