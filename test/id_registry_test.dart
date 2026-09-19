import 'package:id_registry/id_registry.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

void main() {
  late IdRegistryRepositoryImpl registry;

  setUp(() => registry = IdRegistryRepositoryImpl());

  IdPairSet<IdPair<Object>> ids(List<SimpleIdPair> pairs) =>
      IdPairSet<SimpleIdPair>(pairs);

  group('Given an empty registry', () {
    group('When a set of ids is registered', () {
      test('Then every id is registered', () async {
        final result = await registry.register(
          idPairSet: ids([
            const SimpleIdPair('isbn', '9783161484100'),
            const SimpleIdPair('upc', '123456789012'),
          ]),
        );

        result.isRight().should.be(true);
        (await registry.isRegistered(
          idType: 'isbn',
          idCode: '9783161484100',
        )).getOrElse((_) => false).should.be(true);
        (await registry.codesFor(
          idType: 'upc',
        )).getOrElse((_) => <String>{}).should.be({'123456789012'});
      });
    });

    group('When the same set is registered twice', () {
      test('Then the second registration is refused', () async {
        final set = ids([const SimpleIdPair('isbn', '9783161484100')]);
        await registry.register(idPairSet: set);

        final second = await registry.register(idPairSet: set);

        second.isLeft().should.be(true);
        (second.getLeft().getOrElse(() => fail('expected a Left'))
                as DuplicateIdFailure)
            .idType
            .should
            .be('isbn');
      });
    });

    group('When one id in a set is already taken', () {
      test(
        'Then none of the set is registered — registration is atomic',
        () async {
          await registry.register(
            idPairSet: ids([const SimpleIdPair('isbn', '9783161484100')]),
          );

          final refused = await registry.register(
            idPairSet: ids([
              const SimpleIdPair('upc', '999999999999'),
              const SimpleIdPair('isbn', '9783161484100'),
            ]),
          );

          refused.isLeft().should.be(true);
          // The old implementation wrote the first id and then threw: the batch
          // was half-registered and the caller could not tell what had landed.
          (await registry.codesFor(
            idType: 'upc',
          )).getOrElse((_) => <String>{}).should.beEmpty();
        },
      );
    });

    group('When a validator rejects a code', () {
      test('Then nothing in the set is registered', () async {
        registry.registerValidator(
          idType: 'isbn',
          validator: const Isbn13IdValidator(),
        );

        final refused = await registry.register(
          idPairSet: ids([
            const SimpleIdPair('upc', '123456789012'),
            const SimpleIdPair('isbn', 'not-an-isbn'),
          ]),
        );

        (refused.getLeft().getOrElse(() => fail('expected a Left'))
                as InvalidIdFailure)
            .idCode
            .should
            .be('not-an-isbn');
        (await registry.idTypes())
            .getOrElse((_) => <String>{})
            .should
            .not
            .contain('upc');
      });
    });

    group('When a validator accepts a code', () {
      test('Then the registration goes through', () async {
        registry.registerValidator(
          idType: 'isbn',
          validator: const Isbn13IdValidator(),
        );

        final result = await registry.register(
          idPairSet: ids([const SimpleIdPair('isbn', '9783161484100')]),
        );

        result.isRight().should.be(true);
      });
    });
  });

  group('Given a registry holding an id', () {
    group('When the id is unregistered', () {
      test('Then it is free again and no longer listed', () async {
        final set = ids([const SimpleIdPair('isbn', '9783161484100')]);
        await registry.register(idPairSet: set);

        final removed = await registry.unregister(idPairSet: set);

        removed.isRight().should.be(true);
        (await registry.isRegistered(
          idType: 'isbn',
          idCode: '9783161484100',
        )).getOrElse((_) => true).should.be(false);
        (await registry.register(idPairSet: set)).isRight().should.be(true);
      });
    });
  });

  group('Given a registry with a validator and a generator', () {
    group('When its id types are listed', () {
      test('Then configured types are listed even without codes', () async {
        registry.registerValidator(
          idType: 'orcid',
          validator: const OrcidIdValidator(),
        );
        registry.registerGenerator(
          idType: 'shelf',
          generator: IdGeneratorType.uuid,
        );

        (await registry.idTypes())
            .getOrElse((_) => <String>{})
            .should
            .containAll(['orcid', 'shelf']);
      });
    });
  });

  group('Given a registry with no generator for a type', () {
    group('When an id is requested', () {
      test('Then it is refused, and nothing is minted', () async {
        final result = await registry.generateId(idType: 'shelf');

        (result.getLeft().getOrElse(() => fail('expected a Left'))
                as MissingGeneratorFailure)
            .idType
            .should
            .be('shelf');
      });
    });
  });

  group('Given a registry with a uuid generator', () {
    setUp(
      () => registry.registerGenerator(
        idType: 'shelf',
        generator: IdGeneratorType.uuid,
      ),
    );

    group('When ids are requested', () {
      test('Then each is registered and they differ', () async {
        final first = await registry.generateId(idType: 'shelf');
        final second = await registry.generateId(idType: 'shelf');

        final a = first.getOrElse((_) => fail('expected an id'));
        final b = second.getOrElse((_) => fail('expected an id'));

        a.should.not.be(b);
        a.length.should.be(36);
        (await registry.codesFor(
          idType: 'shelf',
        )).getOrElse((_) => <String>{}).should.haveCount(2);
      });
    });
  });

  group('Given a registry with an auto-increment generator', () {
    setUp(
      () => registry.registerGenerator(
        idType: 'shelf',
        generator: IdGeneratorType.autoIncrement,
      ),
    );

    group('When ids are requested in turn', () {
      test('Then they count up from one and are registered', () async {
        (await registry.generateId(
          idType: 'shelf',
        )).getOrElse((_) => fail('expected an id')).should.be('1');
        (await registry.generateId(
          idType: 'shelf',
        )).getOrElse((_) => fail('expected an id')).should.be('2');
        (await registry.codesFor(
          idType: 'shelf',
        )).getOrElse((_) => <String>{}).should.haveCount(2);
      });
    });

    group('When ids already exist under that type', () {
      test('Then generation resumes past them', () async {
        await registry.register(
          idPairSet: ids([
            const SimpleIdPair('shelf', '5'),
            const SimpleIdPair('shelf2', 'x'),
          ]),
        );
        await registry.unregister(
          idPairSet: ids([const SimpleIdPair('shelf2', 'x')]),
        );

        (await registry.generateId(
          idType: 'shelf',
        )).getOrElse((_) => fail('expected an id')).should.be('6');
        (await registry.generateId(
          idType: 'shelf',
        )).getOrElse((_) => fail('expected an id')).should.be('7');
      });
    });

    group('When two ids are requested at once', () {
      test('Then each caller gets a different id', () async {
        final results = await Future.wait([
          registry.generateId(idType: 'shelf'),
          registry.generateId(idType: 'shelf'),
          registry.generateId(idType: 'shelf'),
        ]);

        final codes = results
            .map((result) => result.getOrElse((_) => fail('expected an id')))
            .toSet();

        // Two concurrent calls used to compute the same max and hand out the
        // same id; the registry now runs mutations one at a time.
        codes.should.haveCount(3);
        (await registry.codesFor(
          idType: 'shelf',
        )).getOrElse((_) => <String>{}).should.haveCount(3);
      });
    });
  });

  group('Given a registry with registrations, validators and generators', () {
    group('When it is cleared', () {
      test('Then every part of it is gone, symmetrically', () async {
        registry.registerValidator(
          idType: 'isbn',
          validator: const Isbn13IdValidator(),
        );
        registry.registerGenerator(
          idType: 'shelf',
          generator: IdGeneratorType.autoIncrement,
        );
        await registry.register(
          idPairSet: ids([const SimpleIdPair('isbn', '9783161484100')]),
        );

        (await registry.clear()).isRight().should.be(true);

        (await registry.isRegistered(
          idType: 'isbn',
          idCode: '9783161484100',
        )).getOrElse((_) => true).should.be(false);
        (await registry.idTypes())
            .getOrElse((_) => <String>{})
            .should
            .beEmpty();
        // The old clear() dropped validators but kept generators.
        (await registry.generateId(idType: 'shelf')).isLeft().should.be(true);
      });
    });
  });

  group('Given a registry whose storage refuses to write', () {
    setUp(
      () => registry = IdRegistryRepositoryImpl(storage: _RefusingIdStorage()),
    );

    group('When a set is registered', () {
      test('Then the refusal arrives as a value, not a throw', () async {
        final result = await registry.register(
          idPairSet: ids([const SimpleIdPair('isbn', '9783161484100')]),
        );

        (result.getLeft().getOrElse(() => fail('expected a Left'))
                as RegistryStorageFailure)
            .message
            .should
            .be('storage is unwritable');
      });
    });
  });
}

/// A store that refuses every write, so a storage failure can be exercised.
final class _RefusingIdStorage implements IdStorage {
  @override
  Future<Either<IdStorageFailure, Unit>> add({
    required String idType,
    required String idCode,
  }) async => const Left(StorageUnavailableFailure('storage is unwritable'));

  @override
  Future<Either<IdStorageFailure, Unit>> remove({
    required String idType,
    required String idCode,
  }) async => const Left(StorageUnavailableFailure('storage is unwritable'));

  @override
  Future<Either<IdStorageFailure, Unit>> setCounter({
    required String idType,
    required int value,
  }) async => const Left(StorageUnavailableFailure('storage is unwritable'));

  @override
  Future<Either<IdStorageFailure, Unit>> clear() async =>
      const Left(StorageUnavailableFailure('storage is unwritable'));

  @override
  Future<Either<IdStorageFailure, bool>> contains({
    required String idType,
    required String idCode,
  }) async => const Right(false);

  @override
  Future<Either<IdStorageFailure, Set<String>>> codesFor({
    required String idType,
  }) async => const Right(<String>{});

  @override
  Future<Either<IdStorageFailure, Set<String>>> idTypes() async =>
      const Right(<String>{});

  @override
  Future<Either<IdStorageFailure, int>> counterFor({
    required String idType,
  }) async => const Right(0);
}
