/// Interface for ID validators.
///
/// Implement this to create custom validators for specific ID types.
abstract class IdValidator {
  /// Validates the given value.
  ///
  /// Returns true if the value is valid, false otherwise.
  bool validate({required String value});
}

/// Predefined validators for common ID types.
///
/// These validators can be used with IdRegistry.setValidator() to enforce
/// format validation for specific idTypes.
class IdValidators {
  /// Validates an ORCID identifier.
  ///
  /// ORCID format: XXXX-XXXX-XXXX-XXXX where X is digit, with checksum.
  static bool orcid(String value) {
    final regex = RegExp(r'^\d{4}-\d{4}-\d{4}-\d{3}[\dX]$');
    if (!regex.hasMatch(value)) return false;

    // Remove hyphens and check checksum
    final digits = value.replaceAll('-', '').toUpperCase();
    if (digits.length != 16) return false;

    int total = 0;
    for (int i = 0; i < 15; i++) {
      // Weight: 16 - i (position 0 has weight 16, position 14 has weight 2)
      total += int.parse(digits[i]) * (16 - i);
    }
    final remainder = total % 11;
    final checkDigit = remainder == 0 ? 0 : 11 - remainder;
    final expectedCheck = checkDigit == 10 ? 'X' : checkDigit.toString();

    return digits[15] == expectedCheck;
  }

  /// Validates an ISBN-10 identifier.
  ///
  /// ISBN-10 format: 10 digits, last can be X, with checksum.
  static bool isbn(String value) {
    final clean = value.replaceAll('-', '').toUpperCase();
    if (clean.length != 10) return false;

    int total = 0;
    for (int i = 0; i < 9; i++) {
      final digit = int.tryParse(clean[i]);
      if (digit == null) return false;
      total += digit * (10 - i);
    }

    final checkChar = clean[9];
    final checkDigit = checkChar == 'X' ? 10 : int.tryParse(checkChar);
    if (checkDigit == null) return false;

    total += checkDigit;
    return total % 11 == 0;
  }

  /// Validates an ISBN-13 identifier.
  ///
  /// ISBN-13 format: 13 digits, with checksum.
  static bool isbn13(String value) {
    final clean = value.replaceAll('-', '');
    if (clean.length != 13) return false;

    int total = 0;
    for (int i = 0; i < 12; i++) {
      final digit = int.tryParse(clean[i]);
      if (digit == null) return false;
      total += digit * (i % 2 == 0 ? 1 : 3);
    }

    final checkDigit = int.tryParse(clean[12]);
    if (checkDigit == null) return false;

    final expectedCheck = (10 - (total % 10)) % 10;
    return checkDigit == expectedCheck;
  }
}

/// Concrete implementation of IdValidator for ORCID identifiers.
class OrcidIdValidator implements IdValidator {
  @override
  bool validate({required String value}) => IdValidators.orcid(value);
}

/// Concrete implementation of IdValidator for ISBN-10 identifiers.
class IsbnIdValidator implements IdValidator {
  @override
  bool validate({required String value}) => IdValidators.isbn(value);
}

/// Concrete implementation of IdValidator for ISBN-13 identifiers.
class Isbn13IdValidator implements IdValidator {
  @override
  bool validate({required String value}) => IdValidators.isbn13(value);
}
