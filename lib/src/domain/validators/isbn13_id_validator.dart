import 'id_validator.dart';

/// Validates ISBN-13 codes, including the trailing check digit.
class Isbn13IdValidator implements IdValidator {
  /// Creates an ISBN-13 validator; hyphens are ignored.
  const Isbn13IdValidator();

  @override
  bool validate({required String value}) {
    final clean = value.replaceAll('-', '');
    if (clean.length != 13) return false;

    var total = 0;
    for (var i = 0; i < 12; i++) {
      final digit = int.tryParse(clean[i]);
      if (digit == null) return false;
      total += digit * (i.isEven ? 1 : 3);
    }

    final check = int.tryParse(clean[12]);
    if (check == null) return false;

    return check == (10 - (total % 10)) % 10;
  }
}
