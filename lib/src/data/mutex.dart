import 'dart:async';

/// Serialises the mutating calls of whatever holds it.
///
/// Without it, two registrations of the same id would both pass the check pass
/// and then both write, and two generation calls would mint the same integer:
/// check-then-write is not atomic on its own. Internal to the package — it is
/// deliberately absent from the barrel.
final class Mutex {
  /// Creates an unheld mutex.
  Mutex();

  Future<void> _tail = Future<void>.value();

  /// Runs [action] once everything queued before it has finished.
  Future<T> run<T>(Future<T> Function() action) async {
    final prior = _tail;
    final completer = Completer<void>();
    _tail = completer.future;
    await prior;
    try {
      return await action();
    } finally {
      // Completed without an error on purpose: one failed action must not
      // reject every caller queued behind it.
      completer.complete();
    }
  }
}
