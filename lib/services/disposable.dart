/// Lifecycle contract for services that hold async-only resources (network
/// connections, native renderers, recorders, …).
///
/// Why both [dispose] and [close]:
/// - `ChangeNotifier.dispose()` (which our services extend) is **synchronous**
///   and must remain so — it's what `State.dispose()` and `Widget` teardown
///   calls. We honour that contract.
/// - But teardown of audio renderers, LiveKit rooms, etc. must be **awaited**
///   to prevent overlap with a successor instance (e.g. two HeyGen sessions
///   doubling the greeting audio). Callers that need that guarantee should
///   `await service.close()` *before* `service.dispose()`.
///
/// Convention: [close] is idempotent and safe to call multiple times.
abstract interface class AsyncDisposable {
  /// Tear down all async-held resources. Idempotent.
  Future<void> close();
}
