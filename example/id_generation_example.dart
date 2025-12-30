// ignore_for_file: avoid_print

import 'package:id_registry/id_registry.dart';
import 'package:id_pair_set/id_pair_set.dart';

class ExampleId extends IdPair {
  @override
  final String idType;
  @override
  final String idCode;

  ExampleId({required this.idType, required this.idCode});

  @override
  List<Object?> get props => [idType, idCode];

  @override
  bool get isValid => idCode.isNotEmpty;

  @override
  String get displayName => '$idType: $idCode';

  @override
  IdPair copyWith({dynamic idType, String? idCode}) {
    return ExampleId(
      idType: idType as String? ?? this.idType,
      idCode: idCode ?? this.idCode,
    );
  }
}

void main() async {
  // Create a registry
  final registry = IdRegistry();

  // Register generators for different idTypes
  registry.registerIdTypeGenerator('local', IdGeneratorType.autoIncrement);
  registry.registerIdTypeGenerator('session', IdGeneratorType.uuid);

  print('=== Auto-Increment ID Generation ===');
  // Generate auto-increment IDs
  for (int i = 0; i < 5; i++) {
    final id = await registry.generateId('local');
    print('Generated local ID: $id');
  }

  print('\n=== UUID ID Generation ===');
  // Generate UUID IDs
  for (int i = 0; i < 3; i++) {
    final id = await registry.generateId('session');
    print('Generated session ID: $id');
  }

  print('\n=== Checking Registration ===');
  // Check that generated IDs are registered
  final localIds = await registry.getRegisteredCodes(idType: 'local');
  print('Registered local IDs: $localIds');

  final sessionIds = await registry.getRegisteredCodes(idType: 'session');
  print('Registered session IDs: $sessionIds');

  print('\n=== Generated IDs are Automatically Registered ===');
  // Generated IDs are automatically registered, so they enforce uniqueness
  final anotherLocalId = await registry.generateId('local');
  print('Generated another local ID: $anotherLocalId');

  // Try to register a set with a duplicate generated ID (this would fail)
  // final duplicateSet = IdPairSet([ExampleId(idType: 'local', idCode: anotherLocalId)]);
  // await registry.register(idPairSet: duplicateSet); // Would throw DuplicateIdException

  final allLocalIds = await registry.getRegisteredCodes(idType: 'local');
  print('All registered local IDs: $allLocalIds');
}
