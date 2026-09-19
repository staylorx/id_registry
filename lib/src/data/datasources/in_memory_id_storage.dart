import 'package:fpdart/fpdart.dart';

import '../../domain/datasources/id_storage.dart';
import '../../domain/failures/id_storage_failure.dart';

/// An [IdStorage] held in maps: codes per id type, plus counters.
///
/// The reference implementation and the obvious test double. It cannot fail, so
/// every write answers `Right` — which is exactly what makes it the adapter to
/// run a contract suite against without ceremony.
final class InMemoryIdStorage implements IdStorage {
  /// Creates an empty store.
  InMemoryIdStorage();

  final Map<String, Set<String>> _codes = {};
  final Map<String, int> _counters = {};

  @override
  Future<Either<IdStorageFailure, Unit>> add({
    required String idType,
    required String idCode,
  }) async {
    _codes.putIfAbsent(idType, () => <String>{}).add(idCode);
    return const Right(unit);
  }

  @override
  Future<Either<IdStorageFailure, Unit>> remove({
    required String idType,
    required String idCode,
  }) async {
    final bucket = _codes[idType];
    if (bucket != null) {
      bucket.remove(idCode);
      if (bucket.isEmpty) _codes.remove(idType);
    }
    return const Right(unit);
  }

  @override
  Future<Either<IdStorageFailure, bool>> contains({
    required String idType,
    required String idCode,
  }) async => Right(_codes[idType]?.contains(idCode) ?? false);

  @override
  Future<Either<IdStorageFailure, Set<String>>> codesFor({
    required String idType,
  }) async => Right({...?_codes[idType]});

  @override
  Future<Either<IdStorageFailure, Set<String>>> idTypes() async => Right({
    for (final entry in _codes.entries)
      if (entry.value.isNotEmpty) entry.key,
  });

  @override
  Future<Either<IdStorageFailure, int>> counterFor({
    required String idType,
  }) async => Right(_counters[idType] ?? 0);

  @override
  Future<Either<IdStorageFailure, Unit>> setCounter({
    required String idType,
    required int value,
  }) async {
    _counters[idType] = value;
    return const Right(unit);
  }

  @override
  Future<Either<IdStorageFailure, Unit>> clear() async {
    _codes.clear();
    _counters.clear();
    return const Right(unit);
  }
}
