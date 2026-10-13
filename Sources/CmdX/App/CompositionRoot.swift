import CmdXCore

/// Core services the app runs on.
@MainActor
struct AppServices {
    let coordinator: CutPasteCoordinator
    let highlightPresenter: CutHighlightPresenter
}

/// The single place where concrete implementations are wired to the
/// abstractions the core depends on.
@MainActor
enum CompositionRoot {
    /// No Accessibility call may block the main thread for longer than this.
    private static let accessibilityTimeout: Float = 0.1

    static func makeServices() -> AppServices {
        AXElement.setGlobalMessagingTimeout(accessibilityTimeout)

        let frontmost = WorkspaceFrontmostProvider()
        let pasteboard = SystemPasteboardReader()
        let awaiter = ClipboardChangeAwaiter(pasteboard: pasteboard, scheduler: MainActorScheduler())

        let coordinator = CutPasteCoordinator(
            frontmost: frontmost,
            focus: AccessibilityFocusInspector(),
            pasteboard: pasteboard,
            files: FileManagerExistenceChecker(),
            commands: FinderKeystrokeSender(),
            awaiter: awaiter,
            observer: CompositeCutEventObserver([CutEventLogger(), FailedCutBeeper()])
        )
        let highlightPresenter = CutHighlightPresenter(
            frontmost: frontmost,
            locator: FinderItemLocator(),
            highlighter: DimOverlayHighlighter()
        )
        return AppServices(coordinator: coordinator, highlightPresenter: highlightPresenter)
    }
}
