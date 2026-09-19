import 'dart:io';

import 'package:id_registry/id_registry.dart';
import 'package:path/path.dart' as path;
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

import 'support/id_storage_contract.dart';

void main() {
  late Directory workspace;

  setUp(() => workspace = Directory.systemTemp.createTempSync('id_registry'));
  tearDown(() {
    if (workspace.existsSync()) workspace.deleteSync(recursive: true);
  });

  File storeFile() => File(path.join(workspace.path, 'registry.json'));

  idStorageContract(
    name: 'FileBasedIdStorage',
    build: () => FileBasedIdStorage(file: storeFile()),
    dispose: () {
      if (workspace.existsSync()) workspace.deleteSync(recursive: true);
    },
  );

  group('Given a FileBasedIdStorage that has stored codes', () {
    group('When a second store opens the same file', () {
      test('Then it reads the codes and counters back', () async {
        final first = FileBasedIdStorage(file: storeFile());
        await first.add(idType: 'isbn', idCode: '111');
        await first.add(idType: 'isbn', idCode: '222');
        await first.setCounter(idType: 'shelf', value: 4);

        final second = FileBasedIdStorage(file: storeFile());

        (await second.codesFor(
          idType: 'isbn',
        )).getOrElse((_) => <String>{}).should.be({'111', '222'});
        (await second.counterFor(
          idType: 'shelf',
        )).getOrElse((_) => -1).should.be(4);
      });
    });

    group('When it writes', () {
      test('Then the file exists and is JSON', () async {
        final storage = FileBasedIdStorage(file: storeFile());
        await storage.add(idType: 'isbn', idCode: '111');

        storeFile().existsSync().should.be(true);
        storeFile().readAsStringSync().should.contain('isbn');
      });
    });

    group('When it is cleared', () {
      test('Then the file reflects the clearing for the next reader', () async {
        final storage = FileBasedIdStorage(file: storeFile());
        await storage.add(idType: 'isbn', idCode: '111');
        await storage.clear();

        final next = FileBasedIdStorage(file: storeFile());
        (await next.idTypes())
            .getOrElse((_) => {'unreadable'})
            .should
            .beEmpty();
      });
    });
  });
}
