import 'package:fpdart/fpdart.dart';
import 'package:id_pair_set/id_pair_set.dart';

import '../enums/id_generator_type.dart';
import '../failures/id_registry_failure.dart';
import '../validators/id_validator.dart';

/// Uniqueness, validation and generation for ids across many collections.
///
/// A registry is what turns "this book has these ids" into "no other book may
/// use them": every id is checked against every registered set, optional
/// validators police formats, and optional generators mint fresh ids. Methods
/// answer with `Either` — a refusal is a value, not an exception.
abstract interface class IdRegistryRepository {
  /// Registers every id in [idPairSet] — all of them, or none.
  ///
  /// Refuses with `DuplicateIdFailure` if a type/code pair is already
  /// registered, or `InvalidIdFailure` if a type has a validator that rejects
  /// the code. Nothing is written unless every id passes.
  Future<Either<IdRegistryFailure, Unit>> register({
    required IdPairSet<IdPair<Object>> idPairSet,
  });

  /// Unregisters every id in [idPairSet], freeing them for reuse.
  Future<Either<IdRegistryFailure, Unit>> unregister({
    required IdPairSet<IdPair<Object>> idPairSet,
  });

  /// Whether [idType]`:`[idCode] is already registered.
  Future<Either<IdRegistryFailure, bool>> isRegistered({
    required String idType,
    required String idCode,
  });

  /// Every registered code for [idType].
  Future<Either<IdRegistryFailure, Set<String>>> codesFor({
    required String idType,
  });

  /// Every id type the registry knows: registered codes, validators or
  /// generators.
  Future<Either<IdRegistryFailure, Set<String>>> idTypes();

  /// Sets the validator applied to [idType] whenever it is registered.
  void registerValidator({
    required String idType,
    required IdValidator validator,
  });

  /// Sets the generator [generateId] uses for [idType].
  void registerGenerator({
    required String idType,
    required IdGeneratorType generator,
  });

  /// Mints a free id for [idType] and registers it before returning it.
  ///
  /// Refuses with `MissingGeneratorFailure` when [idType] has no generator.
  Future<Either<IdRegistryFailure, String>> generateId({
    required String idType,
  });

  /// Drops every registration, validator, generator and counter.
  Future<Either<IdRegistryFailure, Unit>> clear();
}
