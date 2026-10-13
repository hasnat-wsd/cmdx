import AppKit
import ApplicationServices
import CmdXCore

/// Uses the Accessibility API to find where focus is in the frontmost
/// application.
///
/// Text editing: only *editable* text controls count, because Finder exposes
/// item names as read-only text fields and those must not block cut and
/// paste. Fails safe: if focus cannot be determined, it reports "editing"
/// so CmdX stays out of the way rather than hijacking ⌘X.
@MainActor
final class AccessibilityFocusInspector: FocusInspecting {
    private static let textRoles: Set<String> = [
        kAXTextFieldRole,
        kAXTextAreaRole,
        kAXComboBoxRole
    ]

    func isTextInputFocused() -> Bool {
        guard let app = frontmostApplication() else {
            Diagnostics.focus.notice("No frontmost application; treating as editing")
            return true
        }

        switch app.lookup(kAXFocusedUIElementAttribute) {
        case .noValue:
            return false
        case .failure:
            Diagnostics.focus.notice("Focused element lookup failed; treating as editing")
            return true
        case .value(let value):
            guard let element = AXValueDecoder.element(value), let role = element.role else {
                Diagnostics.focus.notice("Focused element has no role; treating as editing")
                return true
            }
            return isEditing(element, role: role)
        }
    }

    /// Browser windows are standard windows, and the Desktop has no focused
    /// window. Quick Look, sheets and dialogs report other subroles.
    func isFileBrowserFocused() -> Bool {
        guard let app = frontmostApplication() else { return false }
        switch app.lookup(kAXFocusedWindowAttribute) {
        case .noValue:
            return true
        case .failure:
            return false
        case .value(let value):
            let subrole = AXValueDecoder.element(value)?.string(kAXSubroleAttribute)
            Diagnostics.focus.debug("Focused window subrole \(subrole ?? "none", privacy: .public)")
            return subrole == kAXStandardWindowSubrole
        }
    }

    private func frontmostApplication() -> AXElement? {
        NSWorkspace.shared.frontmostApplication.map { AXElement.application(pid: $0.processIdentifier) }
    }

    private func isEditing(_ element: AXElement, role: String) -> Bool {
        guard Self.textRoles.contains(role) else { return false }
        let editable = element.isSettable(kAXValueAttribute) ?? true
        Diagnostics.focus.notice("Focused \(role, privacy: .public), editable=\(editable, privacy: .public)")
        return editable
    }
}
