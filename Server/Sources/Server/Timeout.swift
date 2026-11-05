import Synchronization

/// Runs `operation`, and returns its result, or `nil` once `timeout` has passed first.
///
/// The operation is not cancelled: database calls built on event loop futures ignore
/// cancellation, so a task group would wait for them anyway. It runs on in the
/// background, and its late result is dropped.
func firstResult<T: Sendable>(
    within timeout: Duration,
    of operation: @escaping @Sendable () async -> T
) async -> T? {
    await withCheckedContinuation { (continuation: CheckedContinuation<T?, Never>) in
        let pending = PendingContinuation(continuation)
        let timer = Task {
            try? await Task.sleep(for: timeout)
            pending.resume(returning: nil)
        }
        Task {
            let result = await operation()
            pending.resume(returning: result)
            timer.cancel()
        }
    }
}

/// A continuation resumed by whichever of two tasks finishes first; the other's call is
/// ignored.
private final class PendingContinuation<T: Sendable>: Sendable {
    private let continuation: Mutex<CheckedContinuation<T?, Never>?>

    init(_ continuation: CheckedContinuation<T?, Never>) {
        self.continuation = Mutex(continuation)
    }

    func resume(returning value: T?) {
        continuation.withLock { $0.take() }?.resume(returning: value)
    }
}
