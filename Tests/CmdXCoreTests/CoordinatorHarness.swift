import CmdXCore
import Foundation

/// Wires a `CutPasteCoordinator` to in-memory fakes.
@MainActor
struct CoordinatorHarness {
    let frontmost = StubFrontmostProvider()
    let focus = StubFocusInspector()
    let pasteboard = FakePasteboard()
    let scheduler = ManualScheduler()
    let events = SpyCutEventObserver()
    let finder: FakeFinder
    let coordinator: CutPasteCoordinator

    init(maxAttempts: Int = 3) {
        finder = FakeFinder(pasteboard: pasteboard)
        let awaiter = ClipboardChangeAwaiter(
            pasteboard: pasteboard,
            scheduler: scheduler,
            maxAttempts: maxAttempts
        )
        coordinator = CutPasteCoordinator(
            frontmost: frontmost,
            focus: focus,
            pasteboard: pasteboard,
            commands: finder,
            awaiter: awaiter,
            observer: events
        )
    }

    /// Presses ⌘X with `items` selected and lets the capture finish.
    @discardableResult
    func cut(_ items: [URL]) -> EventDecision {
        finder.selection = items
        let decision = coordinator.handle(Keys.cut)
        scheduler.runUntilIdle()
        return decision
    }
}
