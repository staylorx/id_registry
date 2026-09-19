import 'package:id_registry/id_registry.dart';

/// Registers books' identifiers, refuses a collision, and mints ids — the four
/// jobs a registry does for a collection of things that have ids.
Future<void> main() async {
  final registry = IdRegistryRepositoryImpl();
  registry.registerValidator(
    idType: 'isbn',
    validator: const Isbn13IdValidator(),
  );
  registry.registerGenerator(
    idType: 'shelf',
    generator: IdGeneratorType.autoIncrement,
  );

  final book = IdPairSet<SimpleIdPair>([
    const SimpleIdPair('isbn', '9783161484100'),
    const SimpleIdPair('upc', '123456789012'),
  ]);

  _report('register book', await registry.register(idPairSet: book));
  _report('register book again', await registry.register(idPairSet: book));

  // A batch that contains one taken id is refused whole: nothing lands.
  final clash = IdPairSet<SimpleIdPair>([
    const SimpleIdPair('upc', '999999999999'),
    const SimpleIdPair('isbn', '9783161484100'),
  ]);
  _report(
    'register a batch with a taken id',
    await registry.register(idPairSet: clash),
  );
  print(
    '  upc still holds: ${(await registry.codesFor(idType: 'upc')).getOrElse((_) => <String>{})}',
  );

  _report(
    'register a malformed isbn',
    await registry.register(
      idPairSet: IdPairSet<SimpleIdPair>([
        const SimpleIdPair('isbn', 'not-an-isbn'),
      ]),
    ),
  );

  _report('mint a shelf id', await registry.generateId(idType: 'shelf'));
  _report('mint another shelf id', await registry.generateId(idType: 'shelf'));
  _report(
    'mint an id with no generator',
    await registry.generateId(idType: 'isbn'),
  );

  print('');
  _report(
    'is the book registered',
    await registry.isRegistered(idType: 'isbn', idCode: '9783161484100'),
  );
  _report('clear the registry', await registry.clear());
  _report(
    'is the book registered now',
    await registry.isRegistered(idType: 'isbn', idCode: '9783161484100'),
  );
}

/// Prints what the registry answered: a value, whether success or refusal.
void _report(String what, Either<IdRegistryFailure, Object> result) {
  result.fold(
    (failure) => print('$what → refused: ${failure.message}'),
    (value) => print('$what → ok: $value'),
  );
}
