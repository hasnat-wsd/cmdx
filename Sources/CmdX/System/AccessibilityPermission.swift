import AppKit
import ApplicationServices

/// Wraps the Accessibility (TCC) permission required to observe and post
/// keyboard events.
@MainActor
final class AccessibilityPermission {
    /// Value of `kAXTrustedCheckOptionPrompt`, spelled out to avoid touching a
    /// mutable C global from Swift 6 strict concurrency.
    private static let promptOptionKey = "AXTrustedCheckOptionPrompt"
    private static let settingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )

    var isGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system prompt that sends the user to System Settings.
    func requestAccess() {
        let options = [Self.promptOptionKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func openSystemSettings() {
        guard let url = Self.settingsURL else { return }
        NSWorkspace.shared.open(url)
    }
}
