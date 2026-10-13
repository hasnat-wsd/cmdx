/// What should happen to an intercepted keyboard event.
public enum EventDecision: Equatable, Sendable {
    /// Deliver the event to the frontmost application unchanged.
    case passThrough
    /// Swallow the event; CmdX has handled it.
    case consume
}
