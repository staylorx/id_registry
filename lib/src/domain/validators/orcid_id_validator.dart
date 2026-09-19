import 'id_validator.dart';

/// Validates ORCID identifiers: `0000-0000-0000-000X`, check digit included.
class OrcidIdValidator implements IdValidator {
  /// Creates an ORCID validator.
  const OrcidIdValidator();

  @override
  bool validate({required String value}) {
    if (!RegExp(r'^\d{4}-\d{4}-\d{4}-\d{3}[\dX]$').hasMatch(value)) {
      return false;
    }

    final digits = value.replaceAll('-', '').toUpperCase();
    var total = 0;
    for (var i = 0; i < 15; i++) {
      // Position i carries weight 16 - i, so the 15th digit weighs 2.
      total += int.parse(digits[i]) * (16 - i);
    }

    final remainder = total % 11;
    final check = remainder == 0 ? 0 : 11 - remainder;
    return digits[15] == (check == 10 ? 'X' : '$check');
  }
}
