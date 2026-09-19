import 'dart:convert';
import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../domain/datasources/id_storage.dart';
import '../../domain/failures/id_storage_failure.dart';

/// An [IdStorage] persisted as one JSON file, loaded on first use.
///
/// Codes are written sorted so the file diffs cleanly, and every mutation is
/// written through before it reports success — a store that only mutated memory
/// would look correct for a session and lose everything after it.
final class FileBasedIdStorage implements IdStorage {
  /// Creates a store backed by [file]; the file is created on first write.
  FileBasedIdStorage({required this.file});

  /// The file holding the JSON state.
  final File file;

  _FileState? _state;

  @override
  Future<Either<IdStorageFailure, Unit>> add({
    required String idType,
    required String idCode,
  }) => _mutate((state) => state.codesFor(idType).add(idCode));

  @override
  Future<Either<IdStorageFailure, Unit>> remove({
    required String idType,
    required String idCode,
  }) => _mutate((state) => state.codesFor(idType).remove(idCode));

  @override
  Future<Either<IdStorageFailure, bool>> contains({
    required String idType,
    required String idCode,
  }) async {
    final loaded = await _load();
    return loaded.fold(
      (failure) => Left(failure),
      (state) => Right(state.codesOf(idType).contains(idCode)),
    );
  }

  @override
  Future<Either<IdStorageFailure, Set<String>>> codesFor({
    required String idType,
  }) async {
    final loaded = await _load();
    return loaded.fold(
      (failure) => Left(failure),
      (state) =>
          Right<IdStorageFailure, Set<String>>({...state.codesOf(idType)}),
    );
  }

  @override
  Future<Either<IdStorageFailure, Set<String>>> idTypes() async {
    final loaded = await _load();
    return loaded.fold(
      (failure) => Left(failure),
      (state) => Right(state.occupiedTypes()),
    );
  }

  @override
  Future<Either<IdStorageFailure, int>> counterFor({
    required String idType,
  }) async {
    final loaded = await _load();
    return loaded.fold(
      (failure) => Left(failure),
      (state) => Right(state.counters[idType] ?? 0),
    );
  }

  @override
  Future<Either<IdStorageFailure, Unit>> setCounter({
    required String idType,
    required int value,
  }) => _mutate((state) => state.counters[idType] = value);

  @override
  Future<Either<IdStorageFailure, Unit>> clear() => _mutate((state) {
    state.codes.clear();
    state.counters.clear();
  });

  /// Applies [change] to the loaded state and writes the file before success.
  Future<Either<IdStorageFailure, Unit>> _mutate(
    void Function(_FileState state) change,
  ) async {
    final loaded = await _load();
    if (loaded.isLeft()) {
      return Left(_failure(loaded));
    }

    final state = loaded.getOrElse((_) => _FileState.empty());
    change(state);
    return _attempt(() async {
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(state.toJson()),
      );
      return unit;
    });
  }

  /// Reads the file once, keeping the result for the life of this store.
  Future<Either<IdStorageFailure, _FileState>> _load() async {
    final cached = _state;
    if (cached != null) return Right(cached);

    final read = await _attempt(() async {
      if (!file.existsSync()) return _FileState.empty();
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return _FileState.empty();
      return _FileState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    });
    return read.map((state) {
      _state = state;
      return state;
    });
  }

  /// Runs [action], turning a thrown exception from the platform into a `Left`.
  static Future<Either<IdStorageFailure, R>> _attempt<R>(
    Future<R> Function() action,
  ) => TaskEither<String, R>.tryCatch(
    action,
    (error, _) => '$error',
  ).mapLeft<IdStorageFailure>(StorageUnavailableFailure.new).run();

  /// The failure inside [either]; only reached when it is a `Left`.
  static IdStorageFailure _failure<E>(Either<IdStorageFailure, E> either) =>
      either.getLeft().getOrElse(
        () => const StorageUnavailableFailure('storage did not answer'),
      );
}

/// The persisted shape: codes per id type, plus the generation counters.
final class _FileState {
  _FileState({required this.codes, required this.counters});

  factory _FileState.empty() => _FileState(codes: {}, counters: {});

  factory _FileState.fromJson(Map<String, dynamic> json) => _FileState(
    codes: {
      for (final entry
          in (json['codes'] as Map<String, dynamic>? ?? {}).entries)
        entry.key: {...(entry.value as List<dynamic>).cast<String>()},
    },
    counters: {
      for (final entry
          in (json['counters'] as Map<String, dynamic>? ?? {}).entries)
        entry.key: entry.value as int,
    },
  );

  final Map<String, Set<String>> codes;
  final Map<String, int> counters;

  Set<String> codesFor(String idType) =>
      codes.putIfAbsent(idType, () => <String>{});

  /// The codes held for [idType], without creating a bucket for an absent type.
  ///
  /// Reads must not allocate: an empty bucket would make [idTypes] claim a type
  /// that holds nothing.
  Set<String> codesOf(String idType) => codes[idType] ?? const <String>{};

  /// Every type actually holding at least one code.
  Set<String> occupiedTypes() => {
    for (final entry in codes.entries)
      if (entry.value.isNotEmpty) entry.key,
  };

  Map<String, dynamic> toJson() => {
    'codes': {
      for (final entry in codes.entries)
        entry.key: entry.value.toList()..sort(),
    },
    'counters': counters,
  };
}
