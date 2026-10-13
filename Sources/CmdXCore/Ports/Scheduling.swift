import Foundation

/// Defers work on the main actor. Abstracted so time can be faked in tests.
@MainActor
public protocol Scheduling: AnyObject {
    func schedule(after delay: TimeInterval, _ work: @escaping @MainActor () -> Void)
}
