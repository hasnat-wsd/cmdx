import Carbon.HIToolbox
import Foundation

/// The user's current keyboard layout, used to translate between physical
/// keys and the characters they type with ⌘ held.
///
/// Translating with ⌘ matters for layouts such as "Dvorak - QWERTY ⌘",
/// which switch to QWERTY while ⌘ is down, exactly as menu shortcuts do.
struct KeyboardLayout {
    /// Virtual key codes cover 0–127.
    private static let keyCodes: Range<UInt16> = 0..<128
    private static let commandModifierState = UInt32((cmdKey >> 8) & 0xFF)

    private let data: Data

    /// `nil` when the active input source has no Unicode key layout.
    static func current() -> KeyboardLayout? {
        guard
            let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
            let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else {
            return nil
        }
        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
        return KeyboardLayout(data: data)
    }

    /// The lowercased character `keyCode` types with ⌘ held.
    func commandCharacter(for keyCode: UInt16) -> String? {
        data.withUnsafeBytes { buffer -> String? in
            guard let layout = buffer.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else {
                return nil
            }
            var deadKeyState: UInt32 = 0
            var length = 0
            var characters = [UniChar](repeating: 0, count: 4)
            let status = UCKeyTranslate(
                layout,
                keyCode,
                UInt16(kUCKeyActionDown),
                Self.commandModifierState,
                UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysMask),
                &deadKeyState,
                characters.count,
                &length,
                &characters
            )
            guard status == noErr, length > 0 else { return nil }
            return String(utf16CodeUnits: characters, count: length).lowercased()
        }
    }

    /// The key that types `character` with ⌘ held, if the layout has one.
    func keyCode(forCommandCharacter character: String) -> UInt16? {
        Self.keyCodes.first { commandCharacter(for: $0) == character }
    }
}
