import AppKit
import CmdXCore

/// Application lifecycle: permission onboarding, starting the keyboard
/// monitor and keeping the status bar and cut highlight in sync with the
/// coordinator.
@MainActor
final class AppController {
    private static let permissionPollInterval: TimeInterval = 2
    private static let clipboardPollInterval: TimeInterval = 1
    /// Fast enough to follow scrolling and window moves smoothly.
    private static let highlightRefreshInterval: TimeInterval = 0.25

    private let coordinator: CutPasteCoordinator
    private let highlightPresenter: CutHighlightPresenter
    private let monitor: EventTapMonitor
    private let permission = AccessibilityPermission()
    private let permissionTimer = RepeatingTimer()
    private let clipboardTimer = RepeatingTimer()
    private let highlightTimer = RepeatingTimer()
    private var statusBar: StatusBarController?

    init(services: AppServices) {
        coordinator = services.coordinator
        highlightPresenter = services.highlightPresenter
        monitor = EventTapMonitor { [coordinator] stroke in
            coordinator.handle(stroke)
        }
    }

    func start() {
        statusBar = StatusBarController(actions: makeMenuActions())
        coordinator.onStateChange = { [weak self] _ in self?.stateDidChange() }
        clipboardTimer.start(interval: Self.clipboardPollInterval) { [weak self] in
            self?.coordinator.invalidateIfClipboardChanged()
        }

        if permission.isGranted {
            activate()
        } else {
            permission.requestAccess()
            waitForPermission()
        }
        render()
    }

    func stop() {
        monitor.stop()
        permissionTimer.stop()
        clipboardTimer.stop()
        highlightTimer.stop()
        highlightPresenter.refresh(for: .idle)
    }

    // MARK: - Private

    private func activate() {
        if monitor.start() {
            permissionTimer.stop()
        } else {
            // Access may have just been granted and not propagated yet.
            waitForPermission()
        }
        render()
    }

    private func waitForPermission() {
        guard !permissionTimer.isRunning else { return }
        permissionTimer.start(interval: Self.permissionPollInterval) { [weak self] in
            guard let self, self.permission.isGranted else { return }
            self.activate()
        }
    }

    private func stateDidChange() {
        render()
        updateHighlight()
    }

    /// Refreshes the fade immediately, then keeps tracking while a cut is pending.
    private func updateHighlight() {
        let state = coordinator.state
        highlightPresenter.refresh(for: state)

        if highlightPresenter.needsTracking(state) {
            guard !highlightTimer.isRunning else { return }
            highlightTimer.start(interval: Self.highlightRefreshInterval) { [weak self] in
                guard let self else { return }
                self.highlightPresenter.refresh(for: self.coordinator.state)
            }
        } else {
            highlightTimer.stop()
        }
    }

    private func render() {
        statusBar?.render(state: coordinator.state, isActive: monitor.isRunning)
    }

    private func makeMenuActions() -> StatusMenuActions {
        StatusMenuActions(
            cancelCut: { [weak self] in self?.coordinator.cancel() },
            grantAccess: { [weak self] in self?.permission.openSystemSettings() },
            quit: { NSApp.terminate(nil) }
        )
    }
}
