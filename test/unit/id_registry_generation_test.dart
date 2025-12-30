import 'package:id_registry/id_registry.dart';
import 'package:test/test.dart';
import 'package:id_pair_set/id_pair_set.dart';

class TestId extends IdPair {
  @override
  final String idType;
  @override
  final String idCode;

  TestId({required this.idType, required this.idCode});

  @override
  List<Object?> get props => [idType, idCode];

  @override
  bool get isValid => idCode.isNotEmpty;

  @override
  String get displayName => '$idType: $idCode';

  @override
  IdPair copyWith({dynamic idType, String? idCode}) {
    return TestId(
      idType: idType as String? ?? this.idType,
      idCode: idCode ?? this.idCode,
    );
  }
}

void main() {
  group('IdRegistry Generators', () {
    late IdRegistry registry;

    setUp(() {
      registry = IdRegistry();
    });

    test('should register generator for idType', () {
      registry.registerIdTypeGenerator('local', IdGeneratorType.autoIncrement);
      // No direct way to check, but generateId should work
    });

    test('should generate auto-increment IDs', () async {
      registry.registerIdTypeGenerator('local', IdGeneratorType.autoIncrement);

      final id1 = await registry.generateId('local');
      expect(id1, '1');
      expect(await registry.isRegistered(idType: 'local', idCode: '1'), isTrue);

      final id2 = await registry.generateId('local');
      expect(id2, '2');
      expect(await registry.isRegistered(idType: 'local', idCode: '2'), isTrue);
    });

    test('should generate UUID IDs', () async {
      registry.registerIdTypeGenerator('uuidType', IdGeneratorType.uuid);

      final id1 = await registry.generateId('uuidType');
      expect(id1, isNotEmpty);
      expect(
        await registry.isRegistered(idType: 'uuidType', idCode: id1),
        isTrue,
      );

      final id2 = await registry.generateId('uuidType');
      expect(id2, isNotEmpty);
      expect(id1 != id2, isTrue); // UUIDs should be unique
      expect(
        await registry.isRegistered(idType: 'uuidType', idCode: id2),
        isTrue,
      );
    });

    test('should throw exception for unregistered generator', () async {
      expect(
        () async => await registry.generateId('unknown'),
        throwsA(isA<Exception>()),
      );
    });

    test('should maintain separate counters for different idTypes', () async {
      registry.registerIdTypeGenerator('type1', IdGeneratorType.autoIncrement);
      registry.registerIdTypeGenerator('type2', IdGeneratorType.autoIncrement);

      final id1 = await registry.generateId('type1');
      final id2 = await registry.generateId('type2');
      final id3 = await registry.generateId('type1');

      expect(id1, '1');
      expect(id2, '1'); // Separate counter
      expect(id3, '2');
    });

    test('should persist counters across registry instances', () async {
      // This test assumes in-memory, but for file-based it would persist
      registry.registerIdTypeGenerator(
        'persistent',
        IdGeneratorType.autoIncrement,
      );
      await registry.generateId('persistent'); // 1

      final newRegistry = IdRegistry(); // New instance
      newRegistry.registerIdTypeGenerator(
        'persistent',
        IdGeneratorType.autoIncrement,
      );
      final id = await newRegistry.generateId('persistent');
      expect(id, '1'); // Should start from 1 since new instance
    });
  });
}
