import CmdXCore
import Foundation

/// Production `Scheduling` backed by Swift concurrency on the main actor.
@MainActor
final class MainActorScheduler: Scheduling {
    func schedule(after delay: TimeInterval, _ work: @escaping @MainActor () -> Void) {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            work()
        }
    }
}
