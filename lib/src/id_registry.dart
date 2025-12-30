import 'exceptions.dart';
import 'validators.dart';
import 'package:id_pair_set/id_pair_set.dart';

/// Registry for managing global uniqueness of all idTypes across multiple IdPairSets.
///
/// This class acts as a "shadow collection" of registered IdPairSets, enforcing uniqueness
/// for all idTypes. It throws DuplicateIdException when attempting to register conflicting
/// identifiers. If uniqueness is not required for certain idTypes, do not use this registry.
class IdRegistry {
  /// Internal registry: idType -> Set of registered idCodes.
  final Map<String, Set<String>> _registry = {};

  /// Validators for each idType.
  final Map<String, bool Function({required String value})> _validators = {};

  /// Creates an IdRegistry that enforces uniqueness for all idTypes.
  IdRegistry();

  /// Registers an IdPairSet, checking for validation and uniqueness violations.
  ///
  /// Throws [ValidationException] if any idCode fails validation for its idType.
  /// Throws [DuplicateIdException] if any idType in the set conflicts
  /// with existing registrations.
  void register(IdPairSet set) {
    for (final pair in set.idPairs) {
      final idType = pair.idType.toString();
      // Validate if validator is set
      if (_validators[idType] != null &&
          !_validators[idType]!(value: pair.idCode)) {
        throw ValidationException(idType: idType, idCode: pair.idCode);
      }
      final codes = _registry.putIfAbsent(idType, () => {});
      if (codes.contains(pair.idCode)) {
        throw DuplicateIdException(idType: idType, idCode: pair.idCode);
      }
      codes.add(pair.idCode);
    }
  }

  /// Unregisters an IdPairSet, removing its identifiers from the registry.
  void unregister(IdPairSet set) {
    for (final pair in set.idPairs) {
      final idType = pair.idType.toString();
      _registry[idType]?.remove(pair.idCode);
    }
  }

  /// Checks if a specific idType and idCode combination is already registered.
  bool isRegistered({required String idType, required String idCode}) {
    return _registry[idType]?.contains(idCode) ?? false;
  }

  /// Returns all registered idCodes for a given idType.
  Set<String> getRegisteredCodes({required String idType}) {
    return Set.from(_registry[idType] ?? {});
  }

  /// Clears all registrations (useful for testing or resetting).
  void clear() {
    _registry.clear();
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
}
