import AppKit
import CmdXCore

/// User actions exposed by the status bar menu.
@MainActor
struct StatusMenuActions {
    let cancelCut: @MainActor () -> Void
    let grantAccess: @MainActor () -> Void
    let quit: @MainActor () -> Void
}

/// Builds the status bar menu for a given app state. Stateless.
@MainActor
enum StatusMenuBuilder {
    private static let maxListedItems = 5

    static func build(state: CutState, isActive: Bool, actions: StatusMenuActions) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(infoItem(headline(state: state, isActive: isActive)))

        if case .ready(let session) = state {
            addItemNames(of: session, to: menu)
            menu.addItem(.separator())
            menu.addItem(ClosureMenuItem(title: "Cancel Cut", handler: actions.cancelCut))
        }

        if !isActive {
            menu.addItem(.separator())
            menu.addItem(ClosureMenuItem(title: "Grant Accessibility Access…", handler: actions.grantAccess))
        }

        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem(title: "Quit CmdX", keyEquivalent: "q", handler: actions.quit))
        return menu
    }

    // MARK: - Private

    private static func headline(state: CutState, isActive: Bool) -> String {
        guard isActive else { return "Accessibility access required" }
        switch state {
        case .idle, .completed:
            return "Select items in Finder and press ⌘X"
        case .capturing:
            return "Cutting…"
        case .ready(let session):
            let count = session.items.count
            return "\(count) item\(count == 1 ? "" : "s") cut — press ⌘V to move"
        }
    }

    private static func addItemNames(of session: CutSession, to menu: NSMenu) {
        let names = session.displayNames
        for name in names.prefix(maxListedItems) {
            menu.addItem(infoItem("  \(name)"))
        }
        let remaining = names.count - maxListedItems
        if remaining > 0 {
            menu.addItem(infoItem("  …and \(remaining) more"))
        }
    }

    private static func infoItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
