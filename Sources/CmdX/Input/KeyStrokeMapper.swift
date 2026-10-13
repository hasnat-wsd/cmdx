import CmdXCore
import CoreGraphics

/// Converts CoreGraphics keyboard events into core `KeyStroke` values.
enum KeyStrokeMapper {
    static func keyStroke(from event: CGEvent) -> KeyStroke {
        KeyStroke(
            keyCode: UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode)),
            modifiers: modifiers(from: event.flags),
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
}
