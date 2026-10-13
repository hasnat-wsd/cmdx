import CmdXCore
import CoreGraphics

/// Triggers Finder menu commands by posting their keyboard equivalents.
///
/// Only two fixed chords are ever posted (⌘C and ⌘⌥V), and only after the
/// coordinator has verified that Finder is the frontmost application.
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
            return (CGKeyCode(KeyCode.c), .maskCommand)
        case .moveHere:
            return (CGKeyCode(KeyCode.v), [.maskCommand, .maskAlternate])
        }
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
