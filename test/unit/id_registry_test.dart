import 'package:id_registry/id_registry.dart';
import 'package:test/test.dart';
import 'package:id_pair_set/id_pair_set.dart';

class TestId extends IdPair {
  @override
  final String idType;
  @override
  final String idCode;

  TestId(this.idType, this.idCode);

  @override
  List<Object?> get props => [idType, idCode];

  @override
  bool get isValid => idCode.isNotEmpty;

  @override
  String get displayName => '$idType: $idCode';

  @override
  IdPair copyWith({dynamic idType, String? idCode}) {
    return TestId(idType as String? ?? this.idType, idCode ?? this.idCode);
  }
}

void main() {
  group('IdRegistry', () {
    late IdRegistry registry;

    setUp(() {
      registry = IdRegistry();
    });

    test('should register unique identifiers successfully', () {
      final set1 = IdPairSet([TestId('isbn', '123'), TestId('upc', '456')]);

      final set2 = IdPairSet([TestId('isbn', '789'), TestId('local', 'abc')]);

      expect(() => registry.register(set1), returnsNormally);
      expect(() => registry.register(set2), returnsNormally);

      expect(registry.isRegistered(idType: 'isbn', idCode: '123'), isTrue);
      expect(registry.isRegistered(idType: 'isbn', idCode: '789'), isTrue);
      expect(registry.isRegistered(idType: 'local', idCode: 'abc'), isTrue);
      expect(registry.isRegistered(idType: 'upc', idCode: '456'), isTrue);
    });

    test(
      'should throw DuplicateIdException for duplicate unique identifiers',
      () {
        final set1 = IdPairSet([TestId('isbn', '123')]);
        final set2 = IdPairSet([TestId('isbn', '123')]); // duplicate

        registry.register(set1);
        expect(
          () => registry.register(set2),
          throwsA(isA<DuplicateIdException>()),
        );
      },
    );

    test('should unregister identifiers', () {
      final set = IdPairSet([TestId('isbn', '123'), TestId('local', 'abc')]);

      registry.register(set);
      expect(registry.isRegistered(idType: 'isbn', idCode: '123'), isTrue);
      expect(registry.isRegistered(idType: 'local', idCode: 'abc'), isTrue);

      registry.unregister(set);
      expect(registry.isRegistered(idType: 'isbn', idCode: '123'), isFalse);
      expect(registry.isRegistered(idType: 'local', idCode: 'abc'), isFalse);
    });

    test('should return registered codes for type', () {
      final set1 = IdPairSet([TestId('isbn', '123')]);
      final set2 = IdPairSet([TestId('isbn', '456')]);

      registry.register(set1);
      registry.register(set2);

      expect(
        registry.getRegisteredCodes(idType: 'isbn'),
        containsAll(['123', '456']),
      );
      expect(registry.getRegisteredCodes(idType: 'local'), isEmpty);
    });

    test('should clear all registrations', () {
      final set = IdPairSet([TestId('isbn', '123')]);
      registry.register(set);
      expect(registry.isRegistered(idType: 'isbn', idCode: '123'), isTrue);

      registry.clear();
      expect(registry.isRegistered(idType: 'isbn', idCode: '123'), isFalse);
    });

    test('should set and use validators', () {
      registry.setValidator(
        'isbn',
        ({required String value}) => value.startsWith('9'),
      );

      final validSet = IdPairSet([TestId('isbn', '978-123')]);
      // bad checksum on purpose
      final invalidSet = IdPairSet([TestId('isbn', '023-456')]);

      expect(() => registry.register(validSet), returnsNormally);
      expect(
        () => registry.register(invalidSet),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should allow overriding validators', () {
      registry.setValidator(
        'isbn',
        ({required String value}) => value.length > 5,
      );
      registry.setValidator(
        'isbn',
        ({required String value}) => value.length < 5,
      );

      final validSet = IdPairSet([TestId('isbn', '123')]);
      final invalidSet = IdPairSet([TestId('isbn', '123456')]);

      expect(() => registry.register(validSet), returnsNormally);
      expect(
        () => registry.register(invalidSet),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should not validate if no validator set', () {
      final set = IdPairSet([TestId('isbn', 'invalid')]);
      expect(() => registry.register(set), returnsNormally);
    });
  });

  group('IdValidators', () {
    test('should validate ORCID', () {
      expect(IdValidators.orcid('0000-0000-0000-0000'), isTrue);
      expect(
        IdValidators.orcid('0000-0000-0000-0001'),
        isFalse,
      ); // invalid checksum
      expect(IdValidators.orcid('invalid'), isFalse);
    });

    test('should validate ISBN', () {
      expect(IdValidators.isbn('0306406152'), isTrue);
      expect(IdValidators.isbn('0306406153'), isFalse); // invalid checksum
      expect(IdValidators.isbn('invalid'), isFalse);
    });

    test('should validate ISBN13', () {
      expect(IdValidators.isbn13('9780306406157'), isTrue);
      expect(IdValidators.isbn13('9780306406158'), isFalse); // invalid checksum
      expect(IdValidators.isbn13('invalid'), isFalse);
    });
  });
}
