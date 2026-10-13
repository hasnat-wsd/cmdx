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

    @Test(arguments: [
        KeyStroke(keyCode: KeyCode.v, modifiers: [.command, .option]),
        KeyStroke(keyCode: KeyCode.v, modifiers: [.command, .shift]),
        KeyStroke(keyCode: KeyCode.x, modifiers: [.command, .control]),
        KeyStroke(keyCode: KeyCode.x, modifiers: []),
        KeyStroke(keyCode: KeyCode.c, modifiers: .command),
        KeyStroke(keyCode: KeyCode.escape, modifiers: .command)
    ])
    func ignoresOtherChords(stroke: KeyStroke) {
        #expect(Shortcut(stroke) == nil)
    }
}
