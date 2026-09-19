/// Everything the registry can refuse to do, as a value rather than a throw.
sealed class IdRegistryFailure {
  /// Allows subclasses to be created by const constructors.
  const IdRegistryFailure();

  /// A caller-facing description of the refusal.
  String get message;
}

/// An id is already registered for its type.
final class DuplicateIdFailure extends IdRegistryFailure {
  /// Records that `idType:idCode` collided with an existing registration.
  const DuplicateIdFailure({required this.idType, required this.idCode});

  /// The id type that collided.
  final String idType;

  /// The code that was already taken.
  final String idCode;

  @override
  String get message => '$idType:$idCode is already registered';
}

/// An id failed the validator registered for its type.
final class InvalidIdFailure extends IdRegistryFailure {
  /// Records that `idType:idCode` did not pass its validator.
  const InvalidIdFailure({required this.idType, required this.idCode});

  /// The id type whose validator refused.
  final String idType;

  /// The code that failed validation.
  final String idCode;

  @override
  String get message => '$idType:$idCode does not pass validation';
}

/// No generator was registered for the requested id type.
final class MissingGeneratorFailure extends IdRegistryFailure {
  /// Records that generation was asked for on an unconfigured type.
  const MissingGeneratorFailure({required this.idType});

  /// The id type that has no generator.
  final String idType;

  @override
  String get message => 'no generator registered for idType: $idType';
}

/// The registry could not reach its storage, or storage refused the write.
final class RegistryStorageFailure extends IdRegistryFailure {
  /// Records a storage-level failure, with [message] explaining it.
  const RegistryStorageFailure(this.message);

  @override
  final String message;
}

/// Generation ran out of room to mint a free id.
final class IdGenerationFailure extends IdRegistryFailure {
  /// Records that [idType] could not be advanced past its existing codes.
  const IdGenerationFailure({required this.idType});

  /// The id type that could not be advanced.
  final String idType;

  @override
  String get message => 'could not mint a free id for idType: $idType';
}
