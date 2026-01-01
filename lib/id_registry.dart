/// A library for managing sets of identifier pairs.
library;

export 'package:id_pair_set/id_pair_set.dart';

export 'src/utils/exceptions.dart';
export 'src/utils/validators.dart';

export 'src/domain/repositories/id_storage.dart';
export 'src/domain/repositories/id_registry_repository.dart';
export 'src/domain/enums/id_generator_type.dart';

export 'src/data/repositories/in_memory_id_storage.dart';
export 'src/data/repositories/file_based_id_storage.dart';
export 'src/data/repositories/caching_storage.dart';
export 'src/data/repositories/id_registry_repository_impl.dart';
