/// Platform-agnostic snapshot of a single key-down event.
public struct KeyStroke: Equatable, Sendable {
    /// Physical key position (layout independent).
    public let keyCode: UInt16
    /// What the key types with ⌘ held in the current keyboard layout,
    /// lowercased. Only resolved for ⌘-only chords; empty otherwise.
    public let characters: String
    public let modifiers: ModifierKeys
    public let isRepeat: Bool

    public init(keyCode: UInt16, characters: String = "", modifiers: ModifierKeys, isRepeat: Bool = false) {
        self.keyCode = keyCode
        self.characters = characters
        self.modifiers = modifiers
        self.isRepeat = isRepeat
    }
}
