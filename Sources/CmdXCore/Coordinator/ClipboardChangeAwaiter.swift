import Foundation

/// Waits (without blocking) for the pasteboard to change after asking
/// Finder to copy, giving up after a bounded number of polls.
@MainActor
public final class ClipboardChangeAwaiter {
    private let pasteboard: PasteboardReading
    private let scheduler: Scheduling
    private let pollInterval: TimeInterval
    private let maxAttempts: Int

    public init(
        pasteboard: PasteboardReading,
        scheduler: Scheduling,
        pollInterval: TimeInterval = 0.05,
        maxAttempts: Int = 20
    ) {
        self.pasteboard = pasteboard
        self.scheduler = scheduler
        self.pollInterval = pollInterval
        self.maxAttempts = max(1, maxAttempts)
    }

    /// Calls `completion(true)` once `changeCount` differs from `baseline`,
    /// or `completion(false)` if it does not change in time.
    public func awaitChange(from baseline: Int, completion: @escaping @MainActor (Bool) -> Void) {
        poll(baseline: baseline, attempt: 1, completion: completion)
    }

    private func poll(baseline: Int, attempt: Int, completion: @escaping @MainActor (Bool) -> Void) {
        scheduler.schedule(after: pollInterval) { [weak self] in
            guard let self else { return }
            if self.pasteboard.changeCount != baseline {
                completion(true)
            } else if attempt >= self.maxAttempts {
                completion(false)
            } else {
                self.poll(baseline: baseline, attempt: attempt + 1, completion: completion)
            }
        }
    }
}
