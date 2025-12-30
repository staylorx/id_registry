/// A library for managing sets of identifier pairs.
library;

export 'src/utils/exceptions.dart';
export 'src/utils/validators.dart';

export 'src/domain/repositories/id_storage.dart';

export 'src/data/repositories/in_memory_id_storage.dart';
export 'src/data/repositories/file_based_id_storage.dart';
export 'src/data/repositories/caching_storage.dart';

export 'src/id_registry.dart';
