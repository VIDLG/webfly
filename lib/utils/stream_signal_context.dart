import 'dart:async';

import 'package:signals/signals.dart';

/// A small helper for bridging a [Stream] into a [Signal].
///
/// - Maintains a single [StreamSubscription].
/// - Exposes the latest value through [valueSignal].
/// - Exposes the latest error (with stack trace) through [errorSignal].
/// - Call [start] once (or rely on a subclass calling it in its constructor).
/// - Call [dispose] to cancel the subscription.
abstract class StreamSignalContext<T> {
  StreamSignalContext(this.stream, T initialValue)
      : valueSignal = signal<T>(initialValue),
        errorSignal = signal<AsyncError?>(null);

  /// The source stream to listen to.
  final Stream<T> stream;

  /// The latest value, exposed as a signal.
  final Signal<T> valueSignal;

  /// The latest stream error (if any).
  ///
  /// Cleared to `null` when a new value is received.
  final Signal<AsyncError?> errorSignal;

  StreamSubscription<T>? _subscription;

  /// Current active subscription (if started).
  StreamSubscription<T>? get subscription => _subscription;

  bool get isListening => _subscription != null;

  /// Start listening (no-op if already started).
  void start() {
    if (_subscription != null) return;

    _subscription = stream.listen(
      _handleValue,
      onError: _handleError,
    );
  }

  void _handleValue(T value) {
    errorSignal.value = null;
    valueSignal.value = value;
    onValue(value);
  }

  void _handleError(Object error, StackTrace stackTrace) {
    errorSignal.value = AsyncError(error, stackTrace);
    onError(error, stackTrace);
  }

  /// Optional hook called after [valueSignal] update.
  void onValue(T value) {}

  /// Optional hook called after [errorSignal] update.
  void onError(Object error, StackTrace stackTrace) {}

  /// Cancel the subscription.
  Future<void> dispose() async {
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }
}
