import 'package:id_registry/id_registry.dart';
import 'package:test/test.dart';

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
  group('IdRegistry Validators', () {
    late IdRegistry registry;

    setUp(() {
      registry = IdRegistry();
    });

    test('should set and use validators', () {
      registry.setValidator(
        idType: 'isbn',
        validator: ({required String value}) => value.startsWith('9'),
      );

      final validSet = IdPairSet([TestId(idType: 'isbn', idCode: '978-123')]);
      // bad checksum on purpose
      final invalidSet = IdPairSet([TestId(idType: 'isbn', idCode: '023-456')]);

      expect(() => registry.register(idPairSet: validSet), returnsNormally);
      expect(
        () => registry.register(idPairSet: invalidSet),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should allow overriding validators', () {
      registry.setValidator(
        idType: 'isbn',
        validator: ({required String value}) => value.length > 5,
      );
      registry.setValidator(
        idType: 'isbn',
        validator: ({required String value}) => value.length < 5,
      );

      final validSet = IdPairSet([TestId(idType: 'isbn', idCode: '123')]);
      final invalidSet = IdPairSet([TestId(idType: 'isbn', idCode: '123456')]);

      expect(() => registry.register(idPairSet: validSet), returnsNormally);
      expect(
        () => registry.register(idPairSet: invalidSet),
        throwsA(isA<ValidationException>()),
      );
    });

    test('should not validate if no validator set', () {
      final set = IdPairSet([TestId(idType: 'isbn', idCode: 'invalid')]);
      expect(() => registry.register(idPairSet: set), returnsNormally);
    });

    test('getAllRegisteredTypes should return types with validators', () async {
      registry.setValidator(
        idType: 'isbn',
        validator: ({required String value}) => true,
      );
      registry.setValidator(
        idType: 'orcid',
        validator: ({required String value}) => true,
      );

      final types = await registry.getAllRegisteredTypes();
      expect(types, contains('isbn'));
      expect(types, contains('orcid'));
    });
  });

  group('IdValidators', () {
    test('should validate ORCID', () {
      expect(IdValidators.orcid(value: '0000-0000-0000-0000'), isTrue);
      expect(
        IdValidators.orcid(value: '0000-0000-0000-0001'),
        isFalse,
      ); // invalid checksum
      expect(IdValidators.orcid(value: 'invalid'), isFalse);
    });

    test('should validate ISBN', () {
      expect(IdValidators.isbn(value: '0306406152'), isTrue);
      expect(
        IdValidators.isbn(value: '0306406153'),
        isFalse,
      ); // invalid checksum
      expect(IdValidators.isbn(value: 'invalid'), isFalse);
    });

    test('should validate ISBN13', () {
      expect(IdValidators.isbn13(value: '9780306406157'), isTrue);
      expect(
        IdValidators.isbn13(value: '9780306406158'),
        isFalse,
      ); // invalid checksum
      expect(IdValidators.isbn13(value: 'invalid'), isFalse);
    });
  });
}
