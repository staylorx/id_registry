/// Cross-collection uniqueness, validation and generation for id pair sets.
library;

export 'package:fpdart/fpdart.dart';
export 'package:id_pair_set/id_pair_set.dart';

export 'src/data/datasources/cached_id_storage.dart';
export 'src/data/datasources/file_based_id_storage.dart';
export 'src/data/datasources/in_memory_id_storage.dart';
export 'src/data/repositories/id_registry_repository_impl.dart';
export 'src/domain/datasources/id_storage.dart';
export 'src/domain/enums/id_generator_type.dart';
export 'src/domain/failures/id_registry_failure.dart';
export 'src/domain/failures/id_storage_failure.dart';
export 'src/domain/repositories/id_registry_repository.dart';
export 'src/domain/validators/id_validator.dart';
export 'src/domain/validators/isbn13_id_validator.dart';
export 'src/domain/validators/isbn_id_validator.dart';
export 'src/domain/validators/orcid_id_validator.dart';
