import AppKit
import CmdXCore

/// Owns the menu bar icon and reflects the current cut state.
@MainActor
final class StatusBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let actions: StatusMenuActions

    init(actions: StatusMenuActions) {
        self.actions = actions
        configureButton()
    }

    func render(state: CutState, isActive: Bool) {
        statusItem.button?.title = badge(for: state)
        statusItem.button?.appearsDisabled = !isActive
        statusItem.menu = StatusMenuBuilder.build(state: state, isActive: isActive, actions: actions)
    }

    // MARK: - Private

    private func configureButton() {
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: "scissors", accessibilityDescription: "CmdX")
        image?.isTemplate = true
        button.image = image
        button.imagePosition = .imageLeading
    }

    private func badge(for state: CutState) -> String {
        guard case .ready(let session) = state else { return "" }
        return " \(session.items.count)"
    }
}
