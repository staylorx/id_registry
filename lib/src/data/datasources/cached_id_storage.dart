import 'package:fpdart/fpdart.dart';

import '../../domain/datasources/id_storage.dart';
import '../../domain/failures/id_storage_failure.dart';

/// An [IdStorage] decorator that keeps reads in memory and passes writes on.
///
/// A registry re-reads the same ids repeatedly (every registration checks its
/// whole set), so the cache pays for itself on the check pass. Writes go to
/// [inner] first and only then update the cache, so the two cannot disagree.
final class CachedIdStorage implements IdStorage {
  /// Wraps [inner] with a memory cache.
  CachedIdStorage({required IdStorage inner}) : _inner = inner;

  final IdStorage _inner;
  final Map<String, Set<String>> _codes = {};
  final Map<String, int> _counters = {};

  @override
  Future<Either<IdStorageFailure, Unit>> add({
    required String idType,
    required String idCode,
  }) async {
    final written = await _inner.add(idType: idType, idCode: idCode);
    return written.map((_) {
      _codes[idType] = {...?_codes[idType], idCode};
      return unit;
    });
  }

  @override
  Future<Either<IdStorageFailure, Unit>> remove({
    required String idType,
    required String idCode,
  }) async {
    final written = await _inner.remove(idType: idType, idCode: idCode);
    return written.map((_) {
      _codes[idType]?.remove(idCode);
      return unit;
    });
  }

  @override
  Future<Either<IdStorageFailure, bool>> contains({
    required String idType,
    required String idCode,
  }) async {
    final cached = _codes[idType];
    if (cached != null) return Right(cached.contains(idCode));

    final loaded = await codesFor(idType: idType);
    return loaded.map((codes) => codes.contains(idCode));
  }

  @override
  Future<Either<IdStorageFailure, Set<String>>> codesFor({
    required String idType,
  }) async {
    final cached = _codes[idType];
    if (cached != null) return Right({...cached});

    final loaded = await _inner.codesFor(idType: idType);
    return loaded.map((codes) {
      _codes[idType] = {...codes};
      return {...codes};
    });
  }

  @override
  Future<Either<IdStorageFailure, Set<String>>> idTypes() => _inner.idTypes();

  @override
  Future<Either<IdStorageFailure, int>> counterFor({
    required String idType,
  }) async {
    final cached = _counters[idType];
    if (cached != null) return Right(cached);

    final loaded = await _inner.counterFor(idType: idType);
    return loaded.map((value) {
      _counters[idType] = value;
      return value;
    });
  }

  @override
  Future<Either<IdStorageFailure, Unit>> setCounter({
    required String idType,
    required int value,
  }) async {
    final written = await _inner.setCounter(idType: idType, value: value);
    return written.map((_) {
      _counters[idType] = value;
      return unit;
    });
  }

  @override
  Future<Either<IdStorageFailure, Unit>> clear() async {
    final cleared = await _inner.clear();
    return cleared.map((_) {
      _codes.clear();
      _counters.clear();
      return unit;
    });
  }
}
