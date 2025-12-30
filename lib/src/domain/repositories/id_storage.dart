/// Abstract interface for asynchronous storage of ID registry data.
///
/// This allows different async persistence implementations (in-memory, database, etc.)
/// to be plugged into async versions of IdRegistry.
abstract class IdStorage {
  /// Adds an idCode to the set for the given idType asynchronously.
  Future<void> add({required String idType, required String idCode});

  /// Removes an idCode from the set for the given idType asynchronously.
  Future<void> remove({required String idType, required String idCode});

  /// Checks if the idCode exists for the given idType asynchronously.
  Future<bool> contains({required String idType, required String idCode});

  /// Returns all idCodes for the given idType asynchronously.
  Future<Set<String>> getAll({required String idType});

  /// Clears all stored data asynchronously.
  Future<void> clear();
}
