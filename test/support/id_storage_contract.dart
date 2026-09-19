import 'package:id_registry/id_registry.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

/// The behaviour every [IdStorage] adapter must show, run against each one.
///
/// An adapter is only worth adding if it passes this suite unchanged — that is
/// what keeps "swap the storage" a one-line change for a caller.
void idStorageContract({
  required String name,
  required IdStorage Function() build,
  void Function()? dispose,
}) {
  group('Given $name', () {
    late IdStorage storage;

    setUp(() => storage = build());
    tearDown(() => dispose?.call());

    group('When nothing has been stored', () {
      test('Then it holds no codes, no types and a zero counter', () async {
        final codes = await storage.codesFor(idType: 'isbn');
        final types = await storage.idTypes();
        final counter = await storage.counterFor(idType: 'isbn');
        final found = await storage.contains(idType: 'isbn', idCode: '1');

        codes.getOrElse((_) => {'unreadable'}).should.beEmpty();
        types.getOrElse((_) => {'unreadable'}).should.beEmpty();
        counter.getOrElse((_) => -1).should.be(0);
        found.getOrElse((_) => true).should.be(false);
      });
    });

    group('When a code is added', () {
      test('Then it is contained and listed under its type', () async {
        final added = await storage.add(idType: 'isbn', idCode: '111');

        added.isRight().should.be(true);
        (await storage.contains(
          idType: 'isbn',
          idCode: '111',
        )).getOrElse((_) => false).should.be(true);
        (await storage.codesFor(
          idType: 'isbn',
        )).getOrElse((_) => <String>{}).should.contain('111');
        (await storage.idTypes())
            .getOrElse((_) => <String>{})
            .should
            .contain('isbn');
      });

      test('Then adding it twice still stores it once', () async {
        await storage.add(idType: 'isbn', idCode: '111');
        await storage.add(idType: 'isbn', idCode: '111');

        (await storage.codesFor(
          idType: 'isbn',
        )).getOrElse((_) => <String>{}).should.haveCount(1);
      });
    });

    group('When codes are held under two types', () {
      test('Then each type answers for itself', () async {
        await storage.add(idType: 'isbn', idCode: '111');
        await storage.add(idType: 'upc', idCode: '222');

        (await storage.codesFor(
          idType: 'upc',
        )).getOrElse((_) => <String>{}).should.be({'222'});
        (await storage.idTypes())
            .getOrElse((_) => <String>{})
            .should
            .containAll(['isbn', 'upc']);
      });
    });

    group('When a code is removed', () {
      test(
        'Then only that code goes, and an absent removal succeeds',
        () async {
          await storage.add(idType: 'isbn', idCode: '111');
          await storage.add(idType: 'isbn', idCode: '222');

          final removed = await storage.remove(idType: 'isbn', idCode: '111');
          final absent = await storage.remove(idType: 'isbn', idCode: 'nope');

          removed.isRight().should.be(true);
          absent.isRight().should.be(true);
          (await storage.codesFor(
            idType: 'isbn',
          )).getOrElse((_) => <String>{}).should.be({'222'});
        },
      );
    });

    group('When a counter is set', () {
      test('Then it reads back, and overwrites', () async {
        (await storage.setCounter(
          idType: 'shelf',
          value: 4,
        )).isRight().should.be(true);
        (await storage.counterFor(
          idType: 'shelf',
        )).getOrElse((_) => -1).should.be(4);

        await storage.setCounter(idType: 'shelf', value: 9);
        (await storage.counterFor(
          idType: 'shelf',
        )).getOrElse((_) => -1).should.be(9);
      });
    });

    group('When it is cleared', () {
      test('Then codes, types and counters are all gone', () async {
        await storage.add(idType: 'isbn', idCode: '111');
        await storage.setCounter(idType: 'shelf', value: 4);

        (await storage.clear()).isRight().should.be(true);

        (await storage.codesFor(
          idType: 'isbn',
        )).getOrElse((_) => {'unreadable'}).should.beEmpty();
        (await storage.idTypes())
            .getOrElse((_) => {'unreadable'})
            .should
            .beEmpty();
        (await storage.counterFor(
          idType: 'shelf',
        )).getOrElse((_) => -1).should.be(0);
      });
    });
  });
}
