import 'id_validator.dart';

/// Validates ISBN-10 codes, including the trailing check digit.
class IsbnIdValidator implements IdValidator {
  /// Creates an ISBN-10 validator; hyphens are ignored.
  const IsbnIdValidator();

  @override
  bool validate({required String value}) {
    final clean = value.replaceAll('-', '').toUpperCase();
    if (clean.length != 10) return false;

    var total = 0;
    for (var i = 0; i < 9; i++) {
      final digit = int.tryParse(clean[i]);
      if (digit == null) return false;
      total += digit * (10 - i);
    }

    final check = clean[9] == 'X' ? 10 : int.tryParse(clean[9]);
    if (check == null) return false;

    return (total + check) % 11 == 0;
  }
}
