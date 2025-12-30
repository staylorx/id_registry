// ignore_for_file: avoid_print

import 'package:id_pair_set/id_pair_set.dart';
import 'package:id_registry/id_registry.dart';

/// Example: Creating and Using Custom Validators
/// ==============================================

/// Custom validator for email addresses
class EmailValidator implements IdValidator {
  @override
  bool validate({required String value}) {
    // Simple email validation regex
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return emailRegex.hasMatch(value);
  }
}

/// Custom validator for user IDs (must be numeric and 6 digits)
class UserIdValidator implements IdValidator {
  @override
  bool validate({required String value}) {
    final numericRegex = RegExp(r'^\d{6}$');
    return numericRegex.hasMatch(value);
  }
}

/// Custom validator for product codes (must start with 'PROD-' and be followed by 4 digits)
class ProductCodeValidator implements IdValidator {
  @override
  bool validate({required String value}) {
    final productRegex = RegExp(r'^PROD-\d{4}$');
    return productRegex.hasMatch(value);
  }
}

Future<void> main() async {
  final registry = IdRegistry();

  // Set up custom validators using the IdValidator interface
  registry.setValidatorFromIdValidator('email', EmailValidator());
  registry.setValidatorFromIdValidator('userId', UserIdValidator());
  registry.setValidatorFromIdValidator('productCode', ProductCodeValidator());

  // Create some test ID pairs
  final validIds = IdPairSet([
    TestId('email', 'user@example.com'),
    TestId('userId', '123456'),
    TestId('productCode', 'PROD-7890'),
  ]);

  final invalidIds = IdPairSet([
    TestId('email', 'invalid-email'),
    TestId('userId', 'abc123'),
    TestId('productCode', 'INVALID-123'),
  ]);

  print('Testing custom validators...\n');

  // Test valid IDs
  try {
    await registry.register(idPairSet: validIds);
    print('✓ Valid IDs registered successfully:');
    for (final id in validIds.idPairs) {
      print('  ${id.idType}: ${id.idCode}');
    }
  } catch (e) {
    print('✗ Unexpected error with valid IDs: $e');
  }

  print('\nTesting invalid IDs...\n');

  // Test invalid IDs (should fail validation)
  try {
    await registry.register(idPairSet: invalidIds);
    print('✗ Invalid IDs were unexpectedly accepted');
  } catch (e) {
    print('✓ Invalid IDs correctly rejected: $e');
  }

  // Clean up
  await registry.clear();
}

/// Simple test ID class for demonstration
class TestId extends IdPair {
  @override
  final String idType;
  @override
  final String idCode;

  TestId(this.idType, this.idCode);

  @override
  List<Object?> get props => [idType, idCode];

  @override
  bool get isValid => idCode.isNotEmpty;

  @override
  String get displayName => '$idType: $idCode';

  @override
  IdPair copyWith({dynamic idType, String? idCode}) {
    return TestId(idType as String? ?? this.idType, idCode ?? this.idCode);
  }
}
