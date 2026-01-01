import '../../domain/repositories/id_storage.dart';
import 'package:id_pair_set/id_pair_set.dart';

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
  CachedIdStorage({required IdStorage storage}) : _storage = storage;

  @override
  Future<void> add({required IdPair idPair}) async {
    // Update cache
    final codes = _cache.putIfAbsent(idPair.idType.toString(), () => {});
    codes.add(idPair.idCode);

    // Delegate to underlying storage
    await _storage.add(idPair: idPair);
  }

  @override
  Future<void> remove({required IdPair idPair}) async {
    // Update cache
    _cache[idPair.idType.toString()]?.remove(idPair.idCode);

    // Delegate to underlying storage
    await _storage.remove(idPair: idPair);
  }

  @override
  Future<bool> contains({required IdPair idPair}) async {
    // Check cache first
    if (_cache.containsKey(idPair.idType.toString())) {
      return _cache[idPair.idType.toString()]!.contains(idPair.idCode);
    } else {
      // Fetch from storage and cache
      final all = await _storage.getAll(idType: idPair.idType.toString());
      _cache[idPair.idType.toString()] = Set.from(all);
      return all.contains(idPair.idCode);
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
  Future<Set<String>> getAllTypes() async {
    // Delegate to underlying storage - no caching for all types
    return await _storage.getAllTypes();
  }

  @override
  Future<void> clear() async {
    // Clear cache
    _cache.clear();

    // Delegate to underlying storage
    await _storage.clear();
  }

  @override
  Future<int> getCounter({required String idType}) async {
    return await _storage.getCounter(idType: idType);
  }

  @override
  Future<void> setCounter({required String idType, required int value}) async {
    await _storage.setCounter(idType: idType, value: value);
  }
}
