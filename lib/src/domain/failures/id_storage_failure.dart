/// Everything that can go wrong while storing registered ids.
///
/// The datasource layer's failure type; a repository maps it upward onto
/// `IdRegistryFailure` so callers never see a storage concern.
sealed class IdStorageFailure {
  /// Allows subclasses to be created by const constructors.
  const IdStorageFailure();

  /// A caller-facing description of what the storage could not do.
  String get message;
}

/// The storage could not be read or written — a missing file, bad permissions,
/// malformed persisted content.
final class StorageUnavailableFailure extends IdStorageFailure {
  /// Records that storage said no, with [message] explaining what failed.
  const StorageUnavailableFailure(this.message);

  @override
  final String message;
}
