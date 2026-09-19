import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:id_pair_set/id_pair_set.dart';
import 'package:uuid/uuid.dart';

import '../../domain/datasources/id_storage.dart';
import '../../domain/enums/id_generator_type.dart';
import '../../domain/failures/id_registry_failure.dart';
import '../../domain/failures/id_storage_failure.dart';
import '../../domain/repositories/id_registry_repository.dart';
import '../../domain/validators/id_validator.dart';
import '../datasources/in_memory_id_storage.dart';

/// An [IdRegistryRepository] over any [IdStorage].
///
/// Mutating calls run one at a time, and [register] checks every id before it
/// writes any of them, undoing what it wrote should a later write fail — so a
/// refused registration leaves the registry exactly as it was.
final class IdRegistryRepositoryImpl implements IdRegistryRepository {
  /// Creates a registry, defaulting to storage held in memory.
  IdRegistryRepositoryImpl({IdStorage? storage})
    : _storage = storage ?? InMemoryIdStorage();

  final IdStorage _storage;
  final Map<String, IdValidator> _validators = {};
  final Map<String, IdGeneratorType> _generators = {};
  final _Mutex _mutex = _Mutex();

  @override
  Future<Either<IdRegistryFailure, Unit>> register({
    required IdPairSet<IdPair<Object>> idPairSet,
  }) => _mutex.run(() async {
    final pairs = idPairSet.pairs;

    // Refuse before writing anything: one refused id stops the registration.
    for (final pair in pairs) {
      final idType = idTypeKey(pair.idType);
      final validator = _validators[idType];
      if (validator != null && !validator.validate(value: pair.idCode)) {
        return Left<IdRegistryFailure, Unit>(
          InvalidIdFailure(idType: idType, idCode: pair.idCode),
        );
      }
    }
    for (final pair in pairs) {
      final idType = idTypeKey(pair.idType);
      final taken = await _storage.contains(
        idType: idType,
        idCode: pair.idCode,
      );
      final refusal = taken.fold<Either<IdRegistryFailure, Unit>>(
        (failure) => Left(RegistryStorageFailure(failure.message)),
        (found) => found
            ? Left(DuplicateIdFailure(idType: idType, idCode: pair.idCode))
            : const Right(unit),
      );
      if (refusal.isLeft()) return refusal;
    }

    // Write pass, with a best-effort undo if storage refuses part way through.
    final written = <(String, String)>[];
    for (final pair in pairs) {
      final idType = idTypeKey(pair.idType);
      final added = await _storage.add(idType: idType, idCode: pair.idCode);
      if (added.isLeft()) {
        await _undo(written);
        return Left<IdRegistryFailure, Unit>(_mapStorage(added));
      }
      written.add((idType, pair.idCode));
    }
    return const Right(unit);
  });

  @override
  Future<Either<IdRegistryFailure, Unit>> unregister({
    required IdPairSet<IdPair<Object>> idPairSet,
  }) => _mutex.run(() async {
    for (final pair in idPairSet.pairs) {
      final removed = await _storage.remove(
        idType: idTypeKey(pair.idType),
        idCode: pair.idCode,
      );
      if (removed.isLeft()) {
        return Left<IdRegistryFailure, Unit>(_mapStorage(removed));
      }
    }
    return const Right(unit);
  });

  @override
  Future<Either<IdRegistryFailure, bool>> isRegistered({
    required String idType,
    required String idCode,
  }) async {
    final found = await _storage.contains(idType: idType, idCode: idCode);
    return found.mapLeft(_toRegistryFailure);
  }

  @override
  Future<Either<IdRegistryFailure, Set<String>>> codesFor({
    required String idType,
  }) async {
    final codes = await _storage.codesFor(idType: idType);
    return codes.mapLeft(_toRegistryFailure);
  }

  @override
  Future<Either<IdRegistryFailure, Set<String>>> idTypes() async {
    final stored = await _storage.idTypes();
    return stored
        .mapLeft(_toRegistryFailure)
        .map((known) => {...known, ..._validators.keys, ..._generators.keys});
  }

  @override
  void registerValidator({
    required String idType,
    required IdValidator validator,
  }) {
    _validators[idType] = validator;
  }

  @override
  void registerGenerator({
    required String idType,
    required IdGeneratorType generator,
  }) {
    _generators[idType] = generator;
  }

  @override
  Future<Either<IdRegistryFailure, String>> generateId({
    required String idType,
  }) => _mutex.run(() async {
    final generator = _generators[idType];
    if (generator == null) {
      return Left<IdRegistryFailure, String>(
        MissingGeneratorFailure(idType: idType),
      );
    }
    return switch (generator) {
      IdGeneratorType.uuid => await _mintUuid(idType: idType),
      IdGeneratorType.autoIncrement => await _mintNextInteger(idType: idType),
    };
  });

  @override
  Future<Either<IdRegistryFailure, Unit>> clear() => _mutex.run(() async {
    final cleared = await _storage.clear();
    if (cleared.isLeft()) {
      return Left<IdRegistryFailure, Unit>(_mapStorage(cleared));
    }
    _validators.clear();
    _generators.clear();
    return const Right(unit);
  });

  /// Mints a UUID v4 for [idType] and registers it before returning it.
  Future<Either<IdRegistryFailure, String>> _mintUuid({
    required String idType,
  }) async {
    final code = const Uuid().v4();
    final added = await _storage.add(idType: idType, idCode: code);
    if (added.isLeft()) {
      return Left<IdRegistryFailure, String>(_mapStorage(added));
    }
    return Right(code);
  }

  /// Mints the next free integer for [idType], driven by the stored counter.
  ///
  /// The counter is seeded from the highest numeric code already there the
  /// first time, so a registry restored from storage resumes instead of
  /// colliding; after that it is one read and one write rather than a scan. The
  /// probe below still skips any code that exists, so a lost counter can waste
  /// an id but can never hand out a duplicate.
  Future<Either<IdRegistryFailure, String>> _mintNextInteger({
    required String idType,
  }) async {
    final stored = await _storage.counterFor(idType: idType);
    if (stored.isLeft()) {
      return Left<IdRegistryFailure, String>(_mapStorage(stored));
    }
    final codes = await _storage.codesFor(idType: idType);
    if (codes.isLeft()) {
      return Left<IdRegistryFailure, String>(_mapStorage(codes));
    }

    final existing = codes.getOrElse((_) => const <String>{});
    var candidate = stored.getOrElse((_) => 0);
    if (candidate == 0) candidate = _highestNumeric(existing);

    var probes = 0;
    while (existing.contains('${candidate + 1}')) {
      candidate++;
      probes++;
      if (probes > existing.length) {
        return Left<IdRegistryFailure, String>(
          IdGenerationFailure(idType: idType),
        );
      }
    }

    final code = '${candidate + 1}';
    final added = await _storage.add(idType: idType, idCode: code);
    if (added.isLeft()) {
      return Left<IdRegistryFailure, String>(_mapStorage(added));
    }
    final saved = await _storage.setCounter(
      idType: idType,
      value: candidate + 1,
    );
    if (saved.isLeft()) {
      return Left<IdRegistryFailure, String>(_mapStorage(saved));
    }
    return Right(code);
  }

  /// Removes the ids written before a failure, oldest last.
  Future<void> _undo(List<(String, String)> written) async {
    for (final (idType, idCode) in written) {
      await _storage.remove(idType: idType, idCode: idCode);
    }
  }

  /// The largest code in [codes] that reads as an integer, or 0.
  static int _highestNumeric(Set<String> codes) {
    var highest = 0;
    for (final code in codes) {
      final value = int.tryParse(code);
      if (value != null && value > highest) highest = value;
    }
    return highest;
  }

  /// Maps a datasource failure onto the registry's own failure type.
  static RegistryStorageFailure _mapStorage<E>(
    Either<IdStorageFailure, E> result,
  ) => result.fold(
    (failure) => RegistryStorageFailure(failure.message),
    (_) => const RegistryStorageFailure('storage reported success'),
  );

  /// Maps a datasource failure, however it arrives, onto a registry failure.
  static IdRegistryFailure _toRegistryFailure(IdStorageFailure failure) =>
      RegistryStorageFailure(failure.message);
}

/// Serialises a registry's mutating calls.
///
/// Without it, two registrations of the same id would both pass the check pass
/// and then both write, and two generation calls would mint the same integer:
/// check-then-write is not atomic on its own.
final class _Mutex {
  Future<void> _tail = Future<void>.value();

  /// Runs [action] once everything queued before it has finished.
  Future<T> run<T>(Future<T> Function() action) async {
    final prior = _tail;
    final completer = Completer<void>();
    _tail = completer.future;
    await prior;
    try {
      return await action();
    } finally {
      completer.complete();
    }
  }
}
