import 'package:id_registry/id_registry.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

import 'support/id_storage_contract.dart';

void main() {
  idStorageContract(
    name: 'CachedIdStorage over InMemoryIdStorage',
    build: () => CachedIdStorage(inner: InMemoryIdStorage()),
  );

  group('Given a CachedIdStorage over another store', () {
    group('When one is cleared', () {
      test('Then the cache is cleared with it', () async {
        final inner = InMemoryIdStorage();
        final cached = CachedIdStorage(inner: inner);
        await cached.add(idType: 'isbn', idCode: '111');
        await cached.contains(idType: 'isbn', idCode: '111');

        await cached.clear();

        (await cached.contains(
          idType: 'isbn',
          idCode: '111',
        )).getOrElse((_) => true).should.be(false);
        (await inner.contains(
          idType: 'isbn',
          idCode: '111',
        )).getOrElse((_) => true).should.be(false);
      });
    });

    group('When a write fails underneath', () {
      test('Then the cache does not gain the unwritten code', () async {
        final cached = CachedIdStorage(inner: _RefusingIdStorage());

        final added = await cached.add(idType: 'isbn', idCode: '111');

        added.isLeft().should.be(true);
        (await cached.contains(
          idType: 'isbn',
          idCode: '111',
        )).getOrElse((_) => true).should.be(false);
      });
    });
  });
}

/// A store that refuses every write, to prove failures are not cached.
final class _RefusingIdStorage implements IdStorage {
  final _inner = InMemoryIdStorage();

  Either<IdStorageFailure, Unit> get _refused =>
      const Left(StorageUnavailableFailure('storage is unwritable'));

  @override
  Future<Either<IdStorageFailure, Unit>> add({
    required String idType,
    required String idCode,
  }) async => _refused;

  @override
  Future<Either<IdStorageFailure, Unit>> remove({
    required String idType,
    required String idCode,
  }) async => _refused;

  @override
  Future<Either<IdStorageFailure, Unit>> setCounter({
    required String idType,
    required int value,
  }) async => _refused;

  @override
  Future<Either<IdStorageFailure, Unit>> clear() async => _refused;

  @override
  Future<Either<IdStorageFailure, bool>> contains({
    required String idType,
    required String idCode,
  }) => _inner.contains(idType: idType, idCode: idCode);

  @override
  Future<Either<IdStorageFailure, Set<String>>> codesFor({
    required String idType,
  }) => _inner.codesFor(idType: idType);

  @override
  Future<Either<IdStorageFailure, Set<String>>> idTypes() => _inner.idTypes();

  @override
  Future<Either<IdStorageFailure, int>> counterFor({required String idType}) =>
      _inner.counterFor(idType: idType);
}
