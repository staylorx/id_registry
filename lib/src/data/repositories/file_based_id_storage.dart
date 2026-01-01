import 'dart:convert';
import 'dart:io';
import '../../domain/repositories/id_storage.dart';
import 'package:id_pair_set/id_pair_set.dart';

/// File-based implementation of AsyncIdStorage that persists data to JSON files asynchronously.
///
/// This implementation demonstrates how to create a persistent async storage layer
/// that saves and loads data from a JSON file on disk using async I/O.
class FileBasedIdStorage implements IdStorage {
  final String filePath;
  Map<String, dynamic> _data = {
    'ids': <String, Set<String>>{},
    'counters': <String, int>{},
  };
  bool _loaded = false;

  /// Creates a file-based async storage with the specified file path.
  ///
  /// Data is loaded lazily on first access to avoid async constructor.
  FileBasedIdStorage({required this.filePath});

  /// Loads data from the JSON file into memory asynchronously.
  Future<void> _loadFromFile() async {
    if (_loaded) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        final ids = jsonData['ids'] as Map<String, dynamic>? ?? {};
        final counters = jsonData['counters'] as Map<String, dynamic>? ?? {};
        _data = {
          'ids': ids.map((key, value) {
            final codes = value as List<dynamic>;
            return MapEntry(key, codes.map((e) => e.toString()).toSet());
          }),
          'counters': counters.map((key, value) => MapEntry(key, value as int)),
        };
      }
    } catch (e) {
      // Silently handle errors during loading - start with empty data
      _data = {'ids': <String, Set<String>>{}, 'counters': <String, int>{}};
    }
    _loaded = true;
  }

  /// Saves the current data to the JSON file asynchronously.
  Future<void> _saveToFile() async {
    try {
      final file = File(filePath);
      final ids = (_data['ids'] as Map<String, Set<String>>).map(
        (key, value) => MapEntry(key, value.toList()),
      );
      final counters = _data['counters'] as Map<String, int>;
      final jsonData = {'ids': ids, 'counters': counters};
      final jsonString = json.encode(jsonData);
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to persist data: $e');
    }
  }

  @override
  Future<void> add({required IdPair idPair}) async {
    await _loadFromFile();
    final codes = (_data['ids'] as Map<String, Set<String>>).putIfAbsent(
      idPair.idType.toString(),
      () => {},
    );
    codes.add(idPair.idCode);
    await _saveToFile();
  }

  @override
  Future<void> remove({required IdPair idPair}) async {
    await _loadFromFile();
    (_data['ids'] as Map<String, Set<String>>)[idPair.idType.toString()]
        ?.remove(idPair.idCode);
    await _saveToFile();
  }

  @override
  Future<bool> contains({required IdPair idPair}) async {
    await _loadFromFile();
    return (_data['ids'] as Map<String, Set<String>>)[idPair.idType.toString()]
            ?.contains(idPair.idCode) ??
        false;
  }

  @override
  Future<Set<String>> getAll({required String idType}) async {
    await _loadFromFile();
    return Set.from((_data['ids'] as Map<String, Set<String>>)[idType] ?? {});
  }

  @override
  Future<Set<String>> getAllTypes() async {
    await _loadFromFile();
    return Set.from((_data['ids'] as Map<String, Set<String>>).keys);
  }

  @override
  Future<void> clear() async {
    await _loadFromFile();
    (_data['ids'] as Map<String, Set<String>>).clear();
    (_data['counters'] as Map<String, int>).clear();
    await _saveToFile();
  }

  @override
  Future<int> getCounter({required String idType}) async {
    await _loadFromFile();
    return (_data['counters'] as Map<String, int>)[idType] ?? 0;
  }

  @override
  Future<void> setCounter({required String idType, required int value}) async {
    await _loadFromFile();
    (_data['counters'] as Map<String, int>)[idType] = value;
    await _saveToFile();
  }
}
