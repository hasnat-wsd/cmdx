import CmdXCore
import Foundation
import Testing

@MainActor
struct CutEventTests {
    @Test func reportsSuccessfulCutAndMove() {
        let harness = CoordinatorHarness()
        harness.cut([Fixtures.file, Fixtures.folder])
        harness.coordinator.handle(Keys.paste)

        #expect(harness.events.recorded == [
            .copyRequested,
            .cutCaptured(itemCount: 2),
            .moveRequested(itemCount: 2)
        ])
    }

    @Test func reportsCutWithNothingSelected() {
        let harness = CoordinatorHarness()
        harness.cut([])

        #expect(harness.events.recorded == [.copyRequested, .cutFailedClipboardUnchanged])
    }

    /// The reported bug: the clipboard held copied text, so a cut that does
    /// not capture files must fail loudly rather than arm a paste.
    @Test func reportsClipboardWithoutFiles() {
        let harness = CoordinatorHarness()
        harness.finder.selection = [Fixtures.file]
        harness.coordinator.handle(Keys.cut)
        harness.pasteboard.urls = []  // Finder changed the clipboard but with no file URLs
        harness.scheduler.runUntilIdle()

        #expect(harness.coordinator.state == .idle)
        #expect(harness.events.recorded.last == .cutFailedNoFiles)
    }

    @Test func reportsWhyShortcutWasIgnored() {
        let harness = CoordinatorHarness()
        harness.focus.textFocused = true
        harness.coordinator.handle(Keys.cut)
        harness.frontmost.finderIsFrontmost = false
        harness.coordinator.handle(Keys.paste)

        #expect(harness.events.recorded == [
            .ignoredWhileEditingText(.cut),
            .ignoredOutsideFinder(.paste)
        ])
    }

    @Test func reportsSwallowedSecondPaste() {
        let harness = CoordinatorHarness()
        harness.cut([Fixtures.file])
        harness.coordinator.handle(Keys.paste)
        harness.coordinator.handle(Keys.paste)

        #expect(harness.events.recorded.last == .pasteSwallowed)
    }

    @Test func reportsEscapeOutsideBrowserWindow() {
        let harness = CoordinatorHarness()
        harness.cut([Fixtures.file])
        harness.focus.fileBrowserFocused = false
        harness.coordinator.handle(Keys.escape)

        #expect(harness.events.recorded.last == .ignoredOutsideFileBrowser(.cancel))
    }

    @Test func reportsCancelOnlyWhenSomethingWasCut() {
        let harness = CoordinatorHarness()
        harness.coordinator.handle(Keys.escape)
        harness.cut([Fixtures.file])
        harness.coordinator.handle(Keys.escape)

        #expect(harness.events.recorded.filter { $0 == .cancelled }.count == 1)
    }
}
