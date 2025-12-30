/// Exception thrown when attempting to register an IdPairSet with duplicate unique identifiers.
class DuplicateIdException implements Exception {
  /// The type of the duplicate ID.
  final String idType;

  /// The code of the duplicate ID.
  final String idCode;

  /// Creates a DuplicateIdException with the given [idType] and [idCode].
  DuplicateIdException({required this.idType, required this.idCode});

  @override
  String toString() =>
      'DuplicateIdException: $idType:$idCode already exists in registry';
}

/// Exception thrown when an ID code fails validation for its type.
class ValidationException implements Exception {
  /// The type of the ID that failed validation.
  final String idType;

  /// The code of the ID that failed validation.
  final String idCode;

  /// Creates a ValidationException with the given [idType] and [idCode].
  ValidationException({required this.idType, required this.idCode});

  @override
  String toString() =>
      'ValidationException: $idType:$idCode does not pass validation';
}
