/// Detects whether the user is typing into a text control (for example
/// renaming a file or using the search field), where ⌘X / ⌘V must keep
/// their normal text-editing meaning.
@MainActor
public protocol TextFocusInspecting: AnyObject {
    func isTextInputFocused() -> Bool
}
