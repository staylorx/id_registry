import '../../domain/repositories/id_storage.dart';

/// In-memory implementation of AsyncIdStorage using `Map<String, Set<String>>`.
///
/// This is the async version of InMemoryIdStorage, wrapping synchronous operations in Futures.
class InMemoryIdStorage implements IdStorage {
  final Map<String, Set<String>> _data = {};
  final Map<String, int> _counters = {};

  @override
  Future<void> add({required String idType, required String idCode}) async {
    final codes = _data.putIfAbsent(idType, () => {});
    codes.add(idCode);
  }

  @override
  Future<void> remove({required String idType, required String idCode}) async {
    _data[idType]?.remove(idCode);
  }

  @override
  Future<bool> contains({
    required String idType,
    required String idCode,
  }) async {
    return _data[idType]?.contains(idCode) ?? false;
  }

  @override
  Future<Set<String>> getAll({required String idType}) async {
    return Set.from(_data[idType] ?? {});
  }

  @override
  Future<void> clear() async {
    _data.clear();
    _counters.clear();
  }

  @override
  Future<int> getCounter(String idType) async {
    return _counters[idType] ?? 0;
  }

  @override
  Future<void> setCounter(String idType, int value) async {
    _counters[idType] = value;
  }
}
