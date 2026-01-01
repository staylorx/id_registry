import '../../utils/exceptions.dart';
import '../../utils/validators.dart';
import 'package:id_pair_set/id_pair_set.dart';

import '../enums/id_generator_type.dart';

/// Repository interface for managing global uniqueness of all idTypes across multiple IdPairSets.
abstract class IdRegistryRepository {
  /// Registers an IdPairSet, checking for validation and uniqueness violations.
  ///
  /// Throws [ValidationException] if any idCode fails validation for its idType.
  /// Throws [DuplicateIdException] if any idType in the set conflicts
  /// with existing registrations.
  Future<void> register({required IdPairSet idPairSet});

  /// Unregisters an IdPairSet, removing its identifiers from the registry.
  Future<void> unregister({required IdPairSet idPairSet});

  /// Checks if a specific idType and idCode combination is already registered.
  Future<bool> isRegistered({required IdPair idPair});

  /// Returns all registered idCodes for a given idType.
  Future<Set<String>> getRegisteredCodes({required String idType});

  /// Returns all idTypes that are currently registered in the registry.
  ///
  /// This includes idTypes that have registered codes, validators, or generators.
  Future<Set<String>> getAllRegisteredTypes();

  /// Clears all registrations (useful for testing or resetting).
  Future<void> clear();

  /// Sets a validator function for a given idType.
  ///
  /// The validator function should return true if the idCode is valid, false otherwise.
  /// If a validator is set, it will be called during registration to validate idCodes.
  void setValidator({
    required String idType,
    required bool Function({required String value}) validator,
  });

  /// Sets a validator instance for a given idType.
  ///
  /// The validator should return true if the idCode is valid, false otherwise.
  /// If a validator is set, it will be called during registration to validate idCodes.
  void setValidatorFromIdValidator({
    required String idType,
    required IdValidator validator,
  });

  /// Registers a generator type for a given idType.
  ///
  /// This allows automatic generation of unique IDs for the idType using either
  /// auto-incrementing integers or UUIDs.
  void registerIdTypeGenerator({
    required String idType,
    required IdGeneratorType type,
  });

  /// Generates a unique ID for the given idType using the registered generator.
  ///
  /// Throws an exception if no generator is registered for the idType.
  /// The generated ID is automatically registered and guaranteed to be unique.
  Future<String> generateId({required String idType});
}
