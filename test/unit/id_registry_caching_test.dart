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
  group('IdRegistry Caching', () {
    late IdRegistry registry;

    setUp(() {
      registry = IdRegistry();
    });

    test('should register unique identifiers successfully', () async {
      final set1 = IdPairSet([
        TestId(idType: 'isbn', idCode: '123'),
        TestId(idType: 'upc', idCode: '456'),
      ]);

      final set2 = IdPairSet([
        TestId(idType: 'isbn', idCode: '789'),
        TestId(idType: 'local', idCode: 'abc'),
      ]);

      await expectLater(registry.register(idPairSet: set1), completes);
      await expectLater(registry.register(idPairSet: set2), completes);

      expect(
        await registry.isRegistered(idType: 'isbn', idCode: '123'),
        isTrue,
      );
      expect(
        await registry.isRegistered(idType: 'isbn', idCode: '789'),
        isTrue,
      );
      expect(
        await registry.isRegistered(idType: 'local', idCode: 'abc'),
        isTrue,
      );
      expect(await registry.isRegistered(idType: 'upc', idCode: '456'), isTrue);
    });

    test(
      'should throw DuplicateIdException for duplicate unique identifiers',
      () async {
        final set1 = IdPairSet([TestId(idType: 'isbn', idCode: '123')]);
        final set2 = IdPairSet([
          TestId(idType: 'isbn', idCode: '123'),
        ]); // duplicate

        await registry.register(idPairSet: set1);
        expect(
          () async => await registry.register(idPairSet: set2),
          throwsA(isA<DuplicateIdException>()),
        );
      },
    );

    test('should unregister identifiers', () async {
      final set = IdPairSet([
        TestId(idType: 'isbn', idCode: '123'),
        TestId(idType: 'local', idCode: 'abc'),
      ]);

      await registry.register(idPairSet: set);
      expect(
        await registry.isRegistered(idType: 'isbn', idCode: '123'),
        isTrue,
      );
      expect(
        await registry.isRegistered(idType: 'local', idCode: 'abc'),
        isTrue,
      );

      await registry.unregister(idPairSet: set);
      expect(
        await registry.isRegistered(idType: 'isbn', idCode: '123'),
        isFalse,
      );
      expect(
        await registry.isRegistered(idType: 'local', idCode: 'abc'),
        isFalse,
      );
    });

    test('should return registered codes for type', () async {
      final set1 = IdPairSet([TestId(idType: 'isbn', idCode: '123')]);
      final set2 = IdPairSet([TestId(idType: 'isbn', idCode: '456')]);

      await registry.register(idPairSet: set1);
      await registry.register(idPairSet: set2);

      expect(
        await registry.getRegisteredCodes(idType: 'isbn'),
        containsAll(['123', '456']),
      );
      expect(await registry.getRegisteredCodes(idType: 'local'), isEmpty);
    });

    test('should clear all registrations', () async {
      final set = IdPairSet([TestId(idType: 'isbn', idCode: '123')]);
      await registry.register(idPairSet: set);
      expect(
        await registry.isRegistered(idType: 'isbn', idCode: '123'),
        isTrue,
      );

      await registry.clear();
      expect(
        await registry.isRegistered(idType: 'isbn', idCode: '123'),
        isFalse,
      );
    });
  });
}
