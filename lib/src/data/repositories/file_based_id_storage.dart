import 'dart:convert';
import 'dart:io';
import '../../domain/repositories/id_storage.dart';

/// File-based implementation of AsyncIdStorage that persists data to JSON files asynchronously.
///
/// This implementation demonstrates how to create a persistent async storage layer
/// that saves and loads data from a JSON file on disk using async I/O.
class FileBasedIdStorage implements IdStorage {
  final String filePath;
  Map<String, Set<String>> _data = {};
  bool _loaded = false;

  /// Creates a file-based async storage with the specified file path.
  ///
  /// Data is loaded lazily on first access to avoid async constructor.
  FileBasedIdStorage(this.filePath);

  /// Loads data from the JSON file into memory asynchronously.
  Future<void> _loadFromFile() async {
    if (_loaded) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        _data = jsonData.map((key, value) {
          final codes = value as List<dynamic>;
          return MapEntry(key, codes.map((e) => e.toString()).toSet());
        });
      }
    } catch (e) {
      // Silently handle errors during loading - start with empty data
      _data = {};
    }
    _loaded = true;
  }

  /// Saves the current data to the JSON file asynchronously.
  Future<void> _saveToFile() async {
    try {
      final file = File(filePath);
      final jsonData = _data.map((key, value) => MapEntry(key, value.toList()));
      final jsonString = json.encode(jsonData);
      await file.writeAsString(jsonString);
    } catch (e) {
      throw Exception('Failed to persist data: $e');
    }
  }

  @override
  Future<void> add({required String idType, required String idCode}) async {
    await _loadFromFile();
    final codes = _data.putIfAbsent(idType, () => {});
    codes.add(idCode);
    await _saveToFile();
  }

  @override
  Future<void> remove({required String idType, required String idCode}) async {
    await _loadFromFile();
    _data[idType]?.remove(idCode);
    await _saveToFile();
  }

  @override
  Future<bool> contains({
    required String idType,
    required String idCode,
  }) async {
    await _loadFromFile();
    return _data[idType]?.contains(idCode) ?? false;
  }

  @override
  Future<Set<String>> getAll({required String idType}) async {
    await _loadFromFile();
    return Set.from(_data[idType] ?? {});
  }

  @override
  Future<void> clear() async {
    await _loadFromFile();
    _data.clear();
    await _saveToFile();
  }
}
