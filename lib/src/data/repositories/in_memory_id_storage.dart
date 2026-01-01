import '../../domain/repositories/id_storage.dart';
import 'package:id_pair_set/id_pair_set.dart';

/// In-memory implementation of AsyncIdStorage using `Map<String, Set<String>>`.
///
/// This is the async version of InMemoryIdStorage, wrapping synchronous operations in Futures.
class InMemoryIdStorage implements IdStorage {
  final Map<String, Set<String>> _data = {};
  final Map<String, int> _counters = {};

  @override
  Future<void> add({required IdPair idPair}) async {
    final codes = _data.putIfAbsent(idPair.idType.toString(), () => {});
    codes.add(idPair.idCode);
  }

  @override
  Future<void> remove({required IdPair idPair}) async {
    _data[idPair.idType.toString()]?.remove(idPair.idCode);
  }

  @override
  Future<bool> contains({required IdPair idPair}) async {
    return _data[idPair.idType.toString()]?.contains(idPair.idCode) ?? false;
  }

  @override
  Future<Set<String>> getAll({required String idType}) async {
    return Set.from(_data[idType] ?? {});
  }

  @override
  Future<Set<String>> getAllTypes() async {
    return Set.from(_data.keys);
  }

  @override
  Future<void> clear() async {
    _data.clear();
    _counters.clear();
  }

  @override
  Future<int> getCounter({required String idType}) async {
    return _counters[idType] ?? 0;
  }

  @override
  Future<void> setCounter({required String idType, required int value}) async {
    _counters[idType] = value;
  }
}
