/// Inspects where keyboard focus is inside the frontmost application.
@MainActor
public protocol FocusInspecting: AnyObject {
    /// Whether the user is typing into a text control (for example renaming
    /// a file or using the search field), where ⌘X / ⌘V must keep their
    /// normal text-editing meaning.
    func isTextInputFocused() -> Bool
    /// Whether focus is in a Finder browser window or on the Desktop, as
    /// opposed to Quick Look, a sheet or a dialog.
    func isFileBrowserFocused() -> Bool
}
