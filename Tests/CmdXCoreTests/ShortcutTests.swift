import CmdXCore
import Testing

struct ShortcutTests {
    @Test func recognisesCommandX() {
        #expect(Shortcut(Keys.cut) == .cut)
    }

    @Test func recognisesCommandV() {
        #expect(Shortcut(Keys.paste) == .paste)
    }

    @Test func recognisesEscape() {
        #expect(Shortcut(Keys.escape) == .cancel)
    }

    /// On Dvorak, "x" is typed by the key at the ANSI "B" position (0x0B).
    @Test func followsTheKeyboardLayout() {
        #expect(Shortcut(KeyStroke(keyCode: 0x0B, characters: "x", modifiers: .command)) == .cut)
        #expect(Shortcut(KeyStroke(keyCode: KeyCode.x, characters: "q", modifiers: .command)) == nil)
    }

    @Test(arguments: [
        KeyStroke(keyCode: KeyCode.v, characters: "v", modifiers: [.command, .option]),
        KeyStroke(keyCode: KeyCode.v, characters: "v", modifiers: [.command, .shift]),
        KeyStroke(keyCode: KeyCode.x, characters: "x", modifiers: [.command, .control]),
        KeyStroke(keyCode: KeyCode.x, characters: "x", modifiers: []),
        KeyStroke(keyCode: KeyCode.c, characters: "c", modifiers: .command),
        KeyStroke(keyCode: KeyCode.escape, modifiers: .command)
    ])
    func ignoresOtherChords(stroke: KeyStroke) {
        #expect(Shortcut(stroke) == nil)
    }
}
