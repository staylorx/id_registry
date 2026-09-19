import 'package:fpdart/fpdart.dart';

import '../failures/id_storage_failure.dart';

/// The mechanical store behind a registry: id codes per id type, plus counters.
///
/// Every method answers with a value — trouble comes back as a `Left`, never as
/// a throw — so adapters can be swapped without changing error handling, and
/// the counters exist so generated ids do not have to re-scan the whole store.
abstract interface class IdStorage {
  /// Records [idCode] under [idType], keeping whatever is already stored.
  Future<Either<IdStorageFailure, Unit>> add({
    required String idType,
    required String idCode,
  });

  /// Removes [idCode] from [idType]; removing an absent code is a success.
  Future<Either<IdStorageFailure, Unit>> remove({
    required String idType,
    required String idCode,
  });

  /// Whether [idCode] is stored under [idType].
  Future<Either<IdStorageFailure, bool>> contains({
    required String idType,
    required String idCode,
  });

  /// Every code stored under [idType].
  Future<Either<IdStorageFailure, Set<String>>> codesFor({
    required String idType,
  });

  /// Every id type holding at least one code.
  Future<Either<IdStorageFailure, Set<String>>> idTypes();

  /// The counter stored for [idType], or 0 when none was ever set.
  Future<Either<IdStorageFailure, int>> counterFor({required String idType});

  /// Stores [value] as the counter for [idType].
  Future<Either<IdStorageFailure, Unit>> setCounter({
    required String idType,
    required int value,
  });

  /// Drops every code and every counter.
  Future<Either<IdStorageFailure, Unit>> clear();
}
