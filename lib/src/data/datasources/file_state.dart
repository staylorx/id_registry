/// The shape a [FileBasedIdStorage] persists: codes per id type, and counters.
///
/// Internal to the package — it is deliberately absent from the barrel.
final class FileState {
  /// Creates a state from the codes and counters already decoded.
  FileState({required this.codes, required this.counters});

  /// Creates the state of a store that has never written anything.
  factory FileState.empty() => FileState(codes: {}, counters: {});

  /// Decodes the persisted JSON object.
  factory FileState.fromJson(Map<String, dynamic> json) => FileState(
    codes: {
      for (final entry
          in (json['codes'] as Map<String, dynamic>? ?? {}).entries)
        entry.key: {...(entry.value as List<dynamic>).cast<String>()},
    },
    counters: {
      for (final entry
          in (json['counters'] as Map<String, dynamic>? ?? {}).entries)
        entry.key: entry.value as int,
    },
  );

  /// Every code stored, by id type.
  final Map<String, Set<String>> codes;

  /// The generation counters, by id type.
  final Map<String, int> counters;

  /// The codes held for [idType], creating the bucket when writing.
  Set<String> codesFor(String idType) =>
      codes.putIfAbsent(idType, () => <String>{});

  /// The codes held for [idType], without creating a bucket for an absent type.
  ///
  /// Reads must not allocate: an empty bucket would make the store claim a type
  /// that holds nothing.
  Set<String> codesOf(String idType) => codes[idType] ?? const <String>{};

  /// Every type actually holding at least one code.
  Set<String> occupiedTypes() => {
    for (final entry in codes.entries)
      if (entry.value.isNotEmpty) entry.key,
  };

  /// Encodes the state as JSON, with codes sorted so the file diffs cleanly.
  Map<String, dynamic> toJson() => {
    'codes': {
      for (final entry in codes.entries)
        entry.key: entry.value.toList()..sort(),
    },
    'counters': counters,
  };
}
