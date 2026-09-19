/// The kind of ids a registry mints for an id type.
enum IdGeneratorType {
  /// Mints `1`, `2`, `3`, … — the next integer not already registered. Only
  /// correct where one writer owns the namespace.
  autoIncrement,

  /// Mints a random UUID v4.
  uuid,
}
