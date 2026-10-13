import AppKit
import ApplicationServices
import CmdXCore

/// Uses the Accessibility API to detect whether the user is editing text in
/// the frontmost application (e.g. renaming a file or typing in search).
///
/// Only *editable* text controls count: Finder exposes item names as
/// read-only text fields, and those must not block cut and paste.
/// Fails safe: if focus cannot be determined, it reports "editing" so CmdX
/// stays out of the way rather than hijacking ⌘X.
@MainActor
final class AccessibilityFocusInspector: TextFocusInspecting {
    private static let textRoles: Set<String> = [
        kAXTextFieldRole,
        kAXTextAreaRole,
        kAXComboBoxRole
    ]

    func isTextInputFocused() -> Bool {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else {
            Diagnostics.focus.notice("No frontmost application; treating as editing")
            return true
        }

        switch AXElement.application(pid: pid).lookup(kAXFocusedUIElementAttribute) {
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

    private func isEditing(_ element: AXElement, role: String) -> Bool {
        guard Self.textRoles.contains(role) else { return false }
        let editable = element.isSettable(kAXValueAttribute) ?? true
        Diagnostics.focus.notice("Focused \(role, privacy: .public), editable=\(editable, privacy: .public)")
        return editable
    }
}
