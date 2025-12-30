import '../../domain/repositories/id_storage.dart';

/// Decorator class that adds caching to any AsyncIdStorage implementation.
///
/// This class wraps an existing AsyncIdStorage and caches the data in memory
/// to improve performance for repeated read operations.
class CachedIdStorage implements IdStorage {
  final IdStorage _storage;
  // TODO: Implement cache invalidation strategy if needed
  // TODO: Consider cache size limits for large datasets? Different strategies?
  final Map<String, Set<String>> _cache = {};

  /// Creates a CachedIdStorage that wraps the given [storage].
  CachedIdStorage(this._storage);

  @override
  Future<void> add({required String idType, required String idCode}) async {
    // Update cache
    final codes = _cache.putIfAbsent(idType, () => {});
    codes.add(idCode);

    // Delegate to underlying storage
    await _storage.add(idType: idType, idCode: idCode);
  }

  @override
  Future<void> remove({required String idType, required String idCode}) async {
    // Update cache
    _cache[idType]?.remove(idCode);

    // Delegate to underlying storage
    await _storage.remove(idType: idType, idCode: idCode);
  }

  @override
  Future<bool> contains({
    required String idType,
    required String idCode,
  }) async {
    // Check cache first
    if (_cache.containsKey(idType)) {
      return _cache[idType]!.contains(idCode);
    } else {
      // Fetch from storage and cache
      final all = await _storage.getAll(idType: idType);
      _cache[idType] = Set.from(all);
      return all.contains(idCode);
    }
  }

  @override
  Future<Set<String>> getAll({required String idType}) async {
    // Check cache first
    if (_cache.containsKey(idType)) {
      return Set.from(_cache[idType]!);
    } else {
      // Fetch from storage and cache
      final all = await _storage.getAll(idType: idType);
      _cache[idType] = Set.from(all);
      return all;
    }
  }

  @override
  Future<void> clear() async {
    // Clear cache
    _cache.clear();

    // Delegate to underlying storage
    await _storage.clear();
  }

  @override
  Future<int> getCounter(String idType) async {
    return await _storage.getCounter(idType);
  }

  @override
  Future<void> setCounter(String idType, int value) async {
    await _storage.setCounter(idType, value);
  }
}
