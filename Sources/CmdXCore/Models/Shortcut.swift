/// The keyboard shortcuts CmdX reacts to. Everything else is ignored.
public enum Shortcut: Equatable, Sendable {
    /// ⌘X – mark the current Finder selection for moving.
    case cut
    /// ⌘V – move previously cut items into the current location.
    case paste
    /// Esc – abandon a pending cut (as Windows Explorer does).
    case cancel

    /// Classifies a key stroke. Letters are matched by the character the
    /// layout produces, as menu key equivalents are, so ⌘X follows the
    /// user's layout (Dvorak, AZERTY…). Modifiers must match exactly, so
    /// ⌘⇧V, ⌘⌥V etc. are left untouched for the system to handle.
    public init?(_ stroke: KeyStroke) {
        if stroke.keyCode == KeyCode.escape, stroke.modifiers.isEmpty {
            self = .cancel
            return
        }
        guard stroke.modifiers == .command else { return nil }
        switch stroke.characters {
        case "x":
            self = .cut
        case "v":
            self = .paste
        default:
            return nil
        }
    }
}
