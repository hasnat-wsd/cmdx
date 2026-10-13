/// Receives `CutEvent`s, e.g. to log them or give audible feedback.
@MainActor
public protocol CutEventObserving: AnyObject {
    func record(_ event: CutEvent)
}

/// Fans one event out to several observers.
@MainActor
public final class CompositeCutEventObserver: CutEventObserving {
    private let observers: [CutEventObserving]

    public init(_ observers: [CutEventObserving]) {
        self.observers = observers
    }

    public func record(_ event: CutEvent) {
        observers.forEach { $0.record(event) }
    }
}
