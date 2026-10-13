import Foundation

/// Small main-run-loop timer wrapper with an explicit start/stop lifecycle.
@MainActor
final class RepeatingTimer {
    private var timer: Timer?

    var isRunning: Bool {
        timer != nil
    }

    func start(interval: TimeInterval, _ tick: @escaping @MainActor () -> Void) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            // Scheduled on the main run loop, so this always runs on the main thread.
            MainActor.assumeIsolated { tick() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
