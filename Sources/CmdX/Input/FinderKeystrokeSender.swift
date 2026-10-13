import CmdXCore
import CoreGraphics

/// Triggers Finder menu commands by posting their keyboard equivalents.
///
/// Only two fixed chords are ever posted (⌘C and ⌘⌥V), and only after the
/// coordinator has verified that Finder is the frontmost application. The
/// key is looked up in the current layout, so on Dvorak ⌘C is posted on
/// the key that types "c", not on the ANSI C position.
@MainActor
final class FinderKeystrokeSender: FinderCommandSending {
    /// A private source keeps physically held keys from leaking into the
    /// synthetic events' modifier state.
    private let source = CGEventSource(stateID: .privateState)

    func send(_ command: FinderCommand) {
        let (keyCode, flags) = Self.chord(for: command)
        post(keyCode: keyCode, flags: flags, keyDown: true)
        post(keyCode: keyCode, flags: flags, keyDown: false)
    }

    private static func chord(for command: FinderCommand) -> (CGKeyCode, CGEventFlags) {
        switch command {
        case .copy:
            return (keyCode(typing: "c", ansiFallback: KeyCode.c), .maskCommand)
        case .moveHere:
            return (keyCode(typing: "v", ansiFallback: KeyCode.v), [.maskCommand, .maskAlternate])
        }
    }

    private static func keyCode(typing character: String, ansiFallback: UInt16) -> CGKeyCode {
        CGKeyCode(KeyboardLayout.current()?.keyCode(forCommandCharacter: character) ?? ansiFallback)
    }

    private func post(keyCode: CGKeyCode, flags: CGEventFlags, keyDown: Bool) {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) else {
            return
        }
        event.flags = flags
        SyntheticEventMarker.mark(event)
        event.post(tap: .cghidEventTap)
    }
}
