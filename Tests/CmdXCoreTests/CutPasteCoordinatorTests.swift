import CmdXCore
import Foundation
import Testing

@MainActor
struct CutPasteCoordinatorTests {
    // MARK: - Cutting

    @Test func cutsSingleFile() {
        let harness = CoordinatorHarness()

        #expect(harness.cut([Fixtures.file]) == .consume)
        #expect(harness.finder.sent == [.copy])
        #expect(harness.coordinator.state == .ready(CutSession(items: [Fixtures.file], changeCount: 1)))
    }

    @Test func cutsMultipleFilesAndFolders() {
        let harness = CoordinatorHarness()
        let items = [Fixtures.file, Fixtures.folder, Fixtures.other]

        harness.cut(items)

        guard case .ready(let session) = harness.coordinator.state else {
            Issue.record("Expected a ready cut session")
            return
        }
        #expect(session.items == items)
        #expect(session.displayNames == ["report.pdf", "Photos", "notes.txt"])
    }

    @Test func returnsToIdleWhenNothingIsSelected() {
        let harness = CoordinatorHarness()

        #expect(harness.cut([]) == .consume)
        #expect(harness.coordinator.state == .idle)
    }

    @Test func ignoresAutoRepeatedCut() {
        let harness = CoordinatorHarness()
        harness.finder.selection = [Fixtures.file]
        let repeated = KeyStroke(keyCode: KeyCode.x, modifiers: .command, isRepeat: true)

        #expect(harness.coordinator.handle(repeated) == .consume)
        #expect(harness.finder.sent.isEmpty)
    }

    // MARK: - Pasting

    @Test func pasteMovesCutItems() {
        let harness = CoordinatorHarness()
        harness.cut([Fixtures.file, Fixtures.folder])

        #expect(harness.coordinator.handle(Keys.paste) == .consume)
        #expect(harness.finder.sent == [.copy, .moveHere])
        #expect(harness.coordinator.state == .completed(changeCount: 1))
    }

    @Test func secondPasteOfSameCutDoesNothing() {
        let harness = CoordinatorHarness()
        harness.cut([Fixtures.file])
        harness.coordinator.handle(Keys.paste)

        #expect(harness.coordinator.handle(Keys.paste) == .consume)
        #expect(harness.finder.sent == [.copy, .moveHere])
    }

    @Test func pasteWithoutCutIsNormalPaste() {
        let harness = CoordinatorHarness()

        #expect(harness.coordinator.handle(Keys.paste) == .passThrough)
        #expect(harness.finder.sent.isEmpty)
    }

    @Test func copyingSomethingElseCancelsTheCut() {
        let harness = CoordinatorHarness()
        harness.cut([Fixtures.file])
        harness.pasteboard.replaceContents(with: [Fixtures.other])

        #expect(harness.coordinator.handle(Keys.paste) == .passThrough)
        #expect(harness.finder.sent == [.copy])
        #expect(harness.coordinator.state == .idle)
    }

    @Test func pasteWhileCapturingIsSwallowed() {
        let harness = CoordinatorHarness()
        harness.finder.selection = [Fixtures.file]
        harness.coordinator.handle(Keys.cut)

        #expect(harness.coordinator.handle(Keys.paste) == .consume)
        #expect(harness.finder.sent == [.copy])
    }

    // MARK: - Cancelling

    @Test func escapeCancelsCutAndStillReachesFinder() {
        let harness = CoordinatorHarness()
        harness.cut([Fixtures.file])

        #expect(harness.coordinator.handle(Keys.escape) == .passThrough)
        #expect(harness.coordinator.state == .idle)
    }

    @Test func cancelDuringCaptureWins() {
        let harness = CoordinatorHarness()
        harness.finder.selection = [Fixtures.file]
        harness.coordinator.handle(Keys.cut)
        harness.coordinator.cancel()
        harness.scheduler.runUntilIdle()

        #expect(harness.coordinator.state == .idle)
    }

    @Test func notifiesObserverOnStateChange() {
        let harness = CoordinatorHarness()
        var observed: [CutState] = []
        harness.coordinator.onStateChange = { observed.append($0) }

        harness.cut([Fixtures.file])

        #expect(observed == [.capturing, .ready(CutSession(items: [Fixtures.file], changeCount: 1))])
    }

    // MARK: - Scope

    @Test func ignoresShortcutsOutsideFinder() {
        let harness = CoordinatorHarness()
        harness.frontmost.finderIsFrontmost = false

        #expect(harness.cut([Fixtures.file]) == .passThrough)
        #expect(harness.finder.sent.isEmpty)
    }

    @Test func ignoresShortcutsWhileEditingText() {
        let harness = CoordinatorHarness()
        harness.focus.textFocused = true

        #expect(harness.cut([Fixtures.file]) == .passThrough)
        #expect(harness.finder.sent.isEmpty)
    }

    @Test func ordinaryKeysAreNeverInspected() {
        let harness = CoordinatorHarness()

        #expect(harness.coordinator.handle(Keys.letterA) == .passThrough)
        #expect(harness.focus.queryCount == 0)
    }
}
