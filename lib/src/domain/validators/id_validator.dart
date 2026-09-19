/// A rule an id code must satisfy for one id type.
abstract interface class IdValidator {
  /// Whether [value] is a well-formed code for this validator's id type.
  bool validate({required String value});
}
