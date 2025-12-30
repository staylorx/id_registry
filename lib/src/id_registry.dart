import 'utils/exceptions.dart';
import 'utils/validators.dart';
import 'domain/repositories/id_storage.dart';
import 'data/repositories/in_memory_id_storage.dart';
import 'package:id_pair_set/id_pair_set.dart';
import 'package:uuid/uuid.dart';

/// Types of ID generators available for idTypes.
enum IdGeneratorType {
  /// Generates auto-incrementing integer IDs starting from 1.
  autoIncrement,

  /// Generates UUID v4 strings.
  uuid,
}

/// Registry for managing global uniqueness of all idTypes across multiple IdPairSets.
///
/// This class acts as a "shadow collection" of registered IdPairSets, enforcing uniqueness
/// for all idTypes. It throws DuplicateIdException when attempting to register conflicting
/// identifiers. If uniqueness is not required for certain idTypes, do not use this registry.
class IdRegistry {
  /// Storage for the registry data.
  final IdStorage _storage;

  /// Validators for each idType.
  final Map<String, bool Function({required String value})> _validators = {};

  /// Generators for each idType.
  final Map<String, IdGeneratorType> _generators = {};

  /// Creates an IdRegistry that enforces uniqueness for all idTypes.
  ///
  /// [storage] allows plugging in different persistence mechanisms.
  /// Defaults to in-memory storage.
  IdRegistry({IdStorage? storage}) : _storage = storage ?? InMemoryIdStorage();

  /// Registers an IdPairSet, checking for validation and uniqueness violations.
  ///
  /// Throws [ValidationException] if any idCode fails validation for its idType.
  /// Throws [DuplicateIdException] if any idType in the set conflicts
  /// with existing registrations.
  Future<void> register({required IdPairSet idPairSet}) async {
    for (final pair in idPairSet.idPairs) {
      final idType = pair.idType.toString();
      // Validate if validator is set
      if (_validators[idType] != null &&
          !_validators[idType]!(value: pair.idCode)) {
        throw ValidationException(idType: idType, idCode: pair.idCode);
      }
      if (await _storage.contains(idType: idType, idCode: pair.idCode)) {
        throw DuplicateIdException(idType: idType, idCode: pair.idCode);
      }
      await _storage.add(idType: idType, idCode: pair.idCode);
    }
  }

  /// Unregisters an IdPairSet, removing its identifiers from the registry.
  Future<void> unregister({required IdPairSet idPairSet}) async {
    for (final pair in idPairSet.idPairs) {
      final idType = pair.idType.toString();
      await _storage.remove(idType: idType, idCode: pair.idCode);
    }
  }

  /// Checks if a specific idType and idCode combination is already registered.
  Future<bool> isRegistered({
    required String idType,
    required String idCode,
  }) async {
    return await _storage.contains(idType: idType, idCode: idCode);
  }

  /// Returns all registered idCodes for a given idType.
  Future<Set<String>> getRegisteredCodes({required String idType}) async {
    return await _storage.getAll(idType: idType);
  }

  /// Clears all registrations (useful for testing or resetting).
  Future<void> clear() async {
    await _storage.clear();
    _validators.clear();
  }

  /// Sets a validator function for a given idType.
  ///
  /// The validator function should return true if the idCode is valid, false otherwise.
  /// If a validator is set, it will be called during registration to validate idCodes.
  void setValidator(
    String idType,
    bool Function({required String value}) validator,
  ) {
    _validators[idType] = validator;
  }

  /// Sets a validator instance for a given idType.
  ///
  /// The validator should return true if the idCode is valid, false otherwise.
  /// If a validator is set, it will be called during registration to validate idCodes.
  void setValidatorFromIdValidator(String idType, IdValidator validator) {
    _validators[idType] = validator.validate;
  }

  /// Registers a generator type for a given idType.
  ///
  /// This allows automatic generation of unique IDs for the idType using either
  /// auto-incrementing integers or UUIDs.
  void registerIdTypeGenerator(String idType, IdGeneratorType type) {
    _generators[idType] = type;
  }

  /// Generates a unique ID for the given idType using the registered generator.
  ///
  /// Throws an exception if no generator is registered for the idType.
  /// The generated ID is automatically registered and guaranteed to be unique.
  Future<String> generateId(String idType) async {
    final generator = _generators[idType];
    if (generator == null) {
      throw Exception('No generator registered for idType: $idType');
    }

    switch (generator) {
      case IdGeneratorType.autoIncrement:
        // TODO: this is wildly inefficient for large sets, improve it later
        // by keeping track of the max ID per idType in storage
        // or using a more efficient data structure.
        String newId;
        do {
          final existing = await _storage.getAll(idType: idType);
          int maxId = 0;
          for (final code in existing) {
            final int? id = int.tryParse(code);
            if (id != null && id > maxId) maxId = id;
          }
          newId = (maxId + 1).toString();
        } while (await _storage.contains(idType: idType, idCode: newId));
        await _storage.add(idType: idType, idCode: newId);
        return newId;
      case IdGeneratorType.uuid:
        final id = const Uuid().v4();
        await _storage.add(idType: idType, idCode: id);
        return id;
    }
  }
}
