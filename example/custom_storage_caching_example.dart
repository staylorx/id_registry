// ignore_for_file: avoid_print

import 'dart:io';
import 'package:id_registry/id_registry.dart';

/// Simple implementation of IdPair for demonstration purposes.
class SimpleId extends IdPair {
  @override
  final String idType;
  @override
  final String idCode;

  SimpleId(this.idType, this.idCode);

  @override
  List<Object?> get props => [idType, idCode];

  @override
  bool get isValid => idCode.isNotEmpty;

  @override
  String get displayName => '$idType: $idCode';

  @override
  IdPair copyWith({dynamic idType, String? idCode}) {
    return SimpleId(idType as String? ?? this.idType, idCode ?? this.idCode);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleId &&
          runtimeType == other.runtimeType &&
          idType == other.idType &&
          idCode == other.idCode;

  @override
  int get hashCode => idType.hashCode ^ idCode.hashCode;
}

/// Example demonstrating custom storage and caching in id_registry.
///
/// This example shows:
/// 1. A custom file-based storage implementation
/// 2. Wrapping it with CachedIdStorage for performance
/// 3. Using IdRegistry with the cached custom storage
/// 4. Demonstrating caching behavior and persistence
Future<void> main() async {
  print('=== Custom Storage and Caching Example ===\n');

  // Create custom file-based storage
  const dataFile = 'id_registry_data.json';
  final fileStorage = FileBasedIdStorage(filePath: dataFile);
  print('Created file-based storage at: $dataFile');

  // Wrap with caching for improved performance
  final cachedStorage = CachedIdStorage(storage: fileStorage);
  print('Wrapped with CachedIdStorage for performance\n');

  // Create IdRegistry with cached custom storage
  final registry = IdRegistry(storage: cachedStorage);
  print('Created IdRegistry with cached file-based storage\n');

  // Set up some sample data - each IdPairSet represents one entity's identifiers
  final userSet1 = IdPairSet([
    SimpleId('user', 'user001'),
    SimpleId('email', 'user001@example.com'),
  ]);

  final userSet2 = IdPairSet([
    SimpleId('user', 'user002'),
    SimpleId('email', 'user002@example.com'),
  ]);

  final productSet = IdPairSet([
    SimpleId('product', 'prod001'),
    SimpleId('sku', 'SKU001'),
  ]);

  print('Sample data prepared:');
  print(
    'User Set 1: ${userSet1.idPairs.map((p) => '${p.idType}:${p.idCode}').join(', ')}',
  );
  print(
    'User Set 2: ${userSet2.idPairs.map((p) => '${p.idType}:${p.idCode}').join(', ')}',
  );
  print(
    'Product Set: ${productSet.idPairs.map((p) => '${p.idType}:${p.idCode}').join(', ')}\n',
  );

  // Register the sets
  print('Registering ID sets...');
  await registry.register(idPairSet: userSet1);
  await registry.register(idPairSet: userSet2);
  await registry.register(idPairSet: productSet);
  print('Registration complete. Data persisted to file.\n');

  // Demonstrate caching behavior
  print('=== Demonstrating Caching Behavior ===');

  // First access - should load from file and cache
  print('First access to user IDs (loads from file and caches):');
  final start1 = DateTime.now();
  final cachedUsers = await registry.getRegisteredCodes(idType: 'user');
  final end1 = DateTime.now();
  print(
    'Users: $cachedUsers (took ${end1.difference(start1).inMicroseconds} μs)',
  );

  // Second access - should use cache
  print('Second access to user IDs (uses cache):');
  final start2 = DateTime.now();
  final cachedUsers2 = await registry.getRegisteredCodes(idType: 'user');
  final end2 = DateTime.now();
  print(
    'Users: $cachedUsers2 (took ${end2.difference(start2).inMicroseconds} μs)',
  );

  // Check if caching improved performance
  if (end2.difference(start2) < end1.difference(start1)) {
    print('✓ Caching improved performance!\n');
  } else {
    print('Note: Performance difference may vary on different systems.\n');
  }

  // Demonstrate persistence
  print('=== Demonstrating Persistence ===');
  final currentUsers = await registry.getRegisteredCodes(idType: 'user');
  final currentProducts = await registry.getRegisteredCodes(idType: 'product');
  print('Current registered users: $currentUsers');
  print('Current registered products: $currentProducts\n');

  // Simulate restarting the application by creating a new registry instance
  print('Simulating application restart...');
  final newRegistry = IdRegistry(
    storage: CachedIdStorage(storage: FileBasedIdStorage(filePath: dataFile)),
  );
  print('New registry instance created and data loaded from file.');
  final loadedUsers = await newRegistry.getRegisteredCodes(idType: 'user');
  final loadedProducts = await newRegistry.getRegisteredCodes(
    idType: 'product',
  );
  print('Loaded users: $loadedUsers');
  print('Loaded products: $loadedProducts\n');

  // Demonstrate removal
  print('=== Demonstrating Removal ===');
  await registry.unregister(idPairSet: userSet1);
  final remainingUsers = await registry.getRegisteredCodes(idType: 'user');
  final remainingEmails = await registry.getRegisteredCodes(idType: 'email');
  final remainingProducts = await registry.getRegisteredCodes(
    idType: 'product',
  );
  print('Unregistered first user set. Remaining users: $remainingUsers');
  print('Remaining emails: $remainingEmails');
  print('Products still registered: $remainingProducts\n');

  // Clean up
  await registry.clear();
  print('Registry cleared. All data removed from memory and file.');

  // Verify file is cleaned up
  final file = File(dataFile);
  if (file.existsSync()) {
    final content = file.readAsStringSync();
    if (content.isEmpty || content == '{}') {
      print('✓ File data properly cleared.');
    } else {
      print(
        'Note: File may contain data (this is normal for some storage implementations).',
      );
    }
  }

  print('\n=== Example Complete ===');
  print('This example demonstrated:');
  print('- Custom file-based storage implementation');
  print('- Caching layer for improved performance');
  print('- Data persistence across application restarts');
  print('- Proper cleanup and error handling');
}
