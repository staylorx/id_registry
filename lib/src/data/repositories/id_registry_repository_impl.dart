import '../../domain/enums/id_generator_type.dart';
import '../../utils/exceptions.dart';
import '../../utils/validators.dart';
import '../../domain/repositories/id_registry_repository.dart';
import '../../domain/repositories/id_storage.dart';
import 'in_memory_id_storage.dart';
import 'package:id_pair_set/id_pair_set.dart';
import 'package:uuid/uuid.dart';

/// Simple implementation of IdPair for internal use in ID generation.
class _IdPairImpl extends IdPair {
  @override
  final dynamic idType;

  @override
  final String idCode;

  _IdPairImpl({required this.idType, required this.idCode});

  @override
  bool get isValid => true;

  @override
  List<Object?> get props => [idType, idCode];

  @override
  String get displayName => '$idType: $idCode';

  @override
  IdPair copyWith({dynamic idType, String? idCode}) {
    return _IdPairImpl(
      idType: idType ?? this.idType,
      idCode: idCode ?? this.idCode,
    );
  }
}

/// Implementation of IdRegistryRepository that enforces uniqueness for all idTypes.
class IdRegistry implements IdRegistryRepository {
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

  @override
  Future<void> register({required IdPairSet idPairSet}) async {
    for (final pair in idPairSet.idPairs) {
      final idType = pair.idType.toString();
      // Validate if validator is set
      if (_validators[idType] != null &&
          !_validators[idType]!(value: pair.idCode)) {
        throw ValidationException(idType: idType, idCode: pair.idCode);
      }
      if (await _storage.contains(idPair: pair)) {
        throw DuplicateIdException(idType: idType, idCode: pair.idCode);
      }
      await _storage.add(idPair: pair);
    }
  }

  @override
  Future<void> unregister({required IdPairSet idPairSet}) async {
    for (final pair in idPairSet.idPairs) {
      await _storage.remove(idPair: pair);
    }
  }

  @override
  Future<bool> isRegistered({required IdPair idPair}) async {
    return await _storage.contains(idPair: idPair);
  }

  @override
  Future<Set<String>> getRegisteredCodes({required String idType}) async {
    return await _storage.getAll(idType: idType);
  }

  @override
  Future<Set<String>> getAllRegisteredTypes() async {
    final storageTypes = await _storage.getAllTypes();
    final validatorTypes = _validators.keys.toSet();
    final generatorTypes = _generators.keys.toSet();
    return storageTypes.union(validatorTypes).union(generatorTypes);
  }

  @override
  Future<void> clear() async {
    await _storage.clear();
    _validators.clear();
  }

  @override
  void setValidator({
    required String idType,
    required bool Function({required String value}) validator,
  }) {
    _validators[idType] = validator;
  }

  @override
  void setValidatorFromIdValidator({
    required String idType,
    required IdValidator validator,
  }) {
    _validators[idType] = validator.validate;
  }

  @override
  void registerIdTypeGenerator({
    required String idType,
    required IdGeneratorType type,
  }) {
    _generators[idType] = type;
  }

  @override
  Future<String> generateId({required String idType}) async {
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
        } while (await _storage.contains(
          idPair: _IdPairImpl(idType: idType, idCode: newId),
        ));
        await _storage.add(
          idPair: _IdPairImpl(idType: idType, idCode: newId),
        );
        return newId;
      case IdGeneratorType.uuid:
        final id = const Uuid().v4();
        await _storage.add(
          idPair: _IdPairImpl(idType: idType, idCode: id),
        );
        return id;
    }
  }
}
