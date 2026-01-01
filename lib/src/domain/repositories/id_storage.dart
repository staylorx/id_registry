import 'package:id_pair_set/id_pair_set.dart';

/// Abstract interface for asynchronous storage of ID registry data.
///
/// This allows different async persistence implementations (in-memory, database, etc.)
/// to be plugged into async versions of IdRegistry.
abstract class IdStorage {
  /// Adds an idCode to the set for the given idType asynchronously.
  Future<void> add({required IdPair idPair});

  /// Removes an idCode from the set for the given idType asynchronously.
  Future<void> remove({required IdPair idPair});

  /// Checks if the idCode exists for the given idType asynchronously.
  Future<bool> contains({required IdPair idPair});

  /// Returns all idCodes for the given idType asynchronously.
  Future<Set<String>> getAll({required String idType});

  /// Clears all stored data asynchronously.
  Future<void> clear();

  /// Returns all idTypes that have registered codes asynchronously.
  Future<Set<String>> getAllTypes();

  /// Gets the current counter value for the given idType asynchronously.
  /// Returns 0 if no counter is set.
  Future<int> getCounter({required String idType});

  /// Sets the counter value for the given idType asynchronously.
  Future<void> setCounter({required String idType, required int value});
}
