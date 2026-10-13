/// Platform-agnostic snapshot of a single key-down event.
public struct KeyStroke: Equatable, Sendable {
    public let keyCode: UInt16
    public let modifiers: ModifierKeys
    public let isRepeat: Bool

    public init(keyCode: UInt16, modifiers: ModifierKeys, isRepeat: Bool = false) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isRepeat = isRepeat
    }
}
