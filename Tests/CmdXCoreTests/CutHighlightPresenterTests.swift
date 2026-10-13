import CmdXCore
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

    @Test func fadesVisibleCutItems() {
        locator.frames = [iconFrame]

        presenter.refresh(for: .ready(session))

        #expect(locator.requestedItems == [session.items])
        #expect(highlighter.shown == [[iconFrame]])
    }

    @Test func removesFadeAfterPaste() {
        locator.frames = [iconFrame]
        presenter.refresh(for: .ready(session))

        presenter.refresh(for: .completed(changeCount: 1))

        #expect(highlighter.hideCount == 1)
    }

    @Test func removesFadeWhenFinderLosesFocus() {
        locator.frames = [iconFrame]
        presenter.refresh(for: .ready(session))
        frontmost.finderIsFrontmost = false

        presenter.refresh(for: .ready(session))

        #expect(highlighter.hideCount == 1)
        #expect(locator.requestedItems.count == 1)
    }

    @Test func removesFadeWhenItemsScrollOutOfView() {
        locator.frames = [iconFrame]
        presenter.refresh(for: .ready(session))
        locator.frames = []

        presenter.refresh(for: .ready(session))

        #expect(highlighter.hideCount == 1)
    }

    @Test func doesNotRepeatHideWhenNothingIsShown() {
        presenter.refresh(for: .idle)
        presenter.refresh(for: .capturing)

        #expect(highlighter.hideCount == 0)
        #expect(locator.requestedItems.isEmpty)
    }

    @Test func tracksOnlyWhileCutIsPending() {
        #expect(presenter.needsTracking(.ready(session)))
        #expect(!presenter.needsTracking(.idle))
        #expect(!presenter.needsTracking(.capturing))
        #expect(!presenter.needsTracking(.completed(changeCount: 1)))
    }
}
