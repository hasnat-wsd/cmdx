/// Native Finder commands CmdX delegates the real file work to.
public enum FinderCommand: Equatable, Sendable {
    /// Edit ▸ Copy (⌘C): puts the selected items on the pasteboard.
    case copy
    /// Edit ▸ Move Item Here (⌘⌥V): moves pasteboard items to the current folder.
    case moveHere
}
