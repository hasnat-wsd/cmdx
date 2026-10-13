import CmdXCore
import CoreGraphics

/// Converts CoreGraphics keyboard events into core `KeyStroke` values.
/// Called from the event tap, which runs on the main thread as the
/// keyboard layout APIs require.
enum KeyStrokeMapper {
    static func keyStroke(from event: CGEvent) -> KeyStroke {
        let keyCode = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
        let modifiers = modifiers(from: event.flags)
        return KeyStroke(
            keyCode: keyCode,
            // Only ⌘-only chords can be shortcuts, so ordinary typing never
            // pays for a layout lookup.
            characters: modifiers == .command ? commandCharacter(for: keyCode) : "",
            modifiers: modifiers,
            isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        )
    }

    static func modifiers(from flags: CGEventFlags) -> ModifierKeys {
        var modifiers: ModifierKeys = []
        if flags.contains(.maskCommand) { modifiers.insert(.command) }
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        return modifiers
    }

    private static func commandCharacter(for keyCode: UInt16) -> String {
        if let layout = KeyboardLayout.current() {
            return layout.commandCharacter(for: keyCode) ?? ""
        }
        // No readable layout: assume ANSI positions.
        switch keyCode {
        case KeyCode.x: return "x"
        case KeyCode.v: return "v"
        default: return ""
        }
    }
}
