/// The keyboard shortcuts CmdX reacts to. Everything else is ignored.
public enum Shortcut: Equatable, Sendable {
    /// ⌘X – mark the current Finder selection for moving.
    case cut
    /// ⌘V – move previously cut items into the current location.
    case paste
    /// Esc – abandon a pending cut (as Windows Explorer does).
    case cancel

    /// Classifies a key stroke. Modifiers must match exactly, so ⌘⇧V,
    /// ⌘⌥V etc. are left untouched for the system to handle.
    public init?(_ stroke: KeyStroke) {
        switch (stroke.keyCode, stroke.modifiers) {
        case (KeyCode.x, [.command]):
            self = .cut
        case (KeyCode.v, [.command]):
            self = .paste
        case (KeyCode.escape, []):
            self = .cancel
        default:
            return nil
        }
    }
}
