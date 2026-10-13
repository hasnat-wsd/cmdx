/// Modifier keys held down during a key press.
public struct ModifierKeys: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let command = ModifierKeys(rawValue: 1 << 0)
    public static let shift = ModifierKeys(rawValue: 1 << 1)
    public static let option = ModifierKeys(rawValue: 1 << 2)
    public static let control = ModifierKeys(rawValue: 1 << 3)
}
