/// Virtual key codes that CmdX cares about.
///
/// Mirrors the `kVK_*` constants from Carbon so the core module stays
/// free of any UI framework imports. Escape sits at the same position on
/// every layout; the letters are ANSI positions, used only as a fallback
/// when the current keyboard layout cannot be read.
public enum KeyCode {
    public static let x: UInt16 = 0x07
    public static let c: UInt16 = 0x08
    public static let v: UInt16 = 0x09
    public static let escape: UInt16 = 0x35
}
