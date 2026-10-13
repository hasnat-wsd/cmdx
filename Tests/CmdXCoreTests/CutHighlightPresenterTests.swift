@testable import CmdXCore
import Foundation
import Testing

@MainActor
struct CutHighlightPresenterTests {
    private let frontmost = StubFrontmostProvider()
    private let locator = StubItemLocator()
    private let highlighter = SpyHighlighter()
    private let presenter: CutHighlightPresenter
    private let session = CutSession(items: [Fixtures.file, Fixtures.folder], changeCount: 1)
    private let iconFrame = CGRect(x: 10, y: 20, width: 64, height: 80)

    init() {
        presenter = CutHighlightPresenter(frontmost: frontmost, locator: locator, highlighter: highlighter)
    }

    private func refresh(_ state: CutState) async {
        presenter.refresh(for: state)
        await presenter.waitForPendingRefresh()
    }

    @Test func fadesVisibleCutItems() async {
        locator.frames = [iconFrame]

        await refresh(.ready(session))

        #expect(locator.requestedItems == [session.items])
        #expect(highlighter.shown == [[iconFrame]])
    }

    @Test func removesFadeAfterPaste() async {
        locator.frames = [iconFrame]
        await refresh(.ready(session))

        await refresh(.completed(session))

        #expect(highlighter.hideCount == 1)
    }

    @Test func removesFadeWhenFinderLosesFocus() async {
        locator.frames = [iconFrame]
        await refresh(.ready(session))
        frontmost.finderIsFrontmost = false

        await refresh(.ready(session))

        #expect(highlighter.hideCount == 1)
        #expect(locator.requestedItems.count == 1)
    }

    @Test func removesFadeWhenItemsScrollOutOfView() async {
        locator.frames = [iconFrame]
        await refresh(.ready(session))
        locator.frames = []

        await refresh(.ready(session))

        #expect(highlighter.hideCount == 1)
    }

    @Test func doesNotRepeatHideWhenNothingIsShown() async {
        await refresh(.idle)
        await refresh(.capturing)

        #expect(highlighter.hideCount == 0)
        #expect(locator.requestedItems.isEmpty)
    }

    /// A slow search must not paint a fade for a cut that ended meanwhile.
    @Test func discardsSearchThatFinishesAfterTheCutEnded() async {
        let slowLocator = SuspendedItemLocator()
        let presenter = CutHighlightPresenter(frontmost: frontmost, locator: slowLocator, highlighter: highlighter)

        presenter.refresh(for: .ready(session))
        await slowLocator.waitUntilRequested()
        presenter.refresh(for: .idle)
        slowLocator.finish(with: [iconFrame])
        await presenter.waitForPendingRefresh()

        #expect(highlighter.shown.isEmpty)
    }

    @Test func skipsRefreshWhileSearchIsRunning() async {
        let slowLocator = SuspendedItemLocator()
        let presenter = CutHighlightPresenter(frontmost: frontmost, locator: slowLocator, highlighter: highlighter)

        presenter.refresh(for: .ready(session))
        await slowLocator.waitUntilRequested()
        presenter.refresh(for: .ready(session))
        slowLocator.finish(with: [iconFrame])
        await presenter.waitForPendingRefresh()

        #expect(slowLocator.requestCount == 1)
        #expect(highlighter.shown == [[iconFrame]])
    }

    @Test func tracksOnlyWhileCutIsPending() {
        #expect(presenter.needsTracking(.ready(session)))
        #expect(!presenter.needsTracking(.idle))
        #expect(!presenter.needsTracking(.capturing))
        #expect(!presenter.needsTracking(.completed(session)))
    }
}
