import CoreGraphics

/// Tags keyboard events posted by CmdX so the event tap never re-processes
/// its own output (which would otherwise cause feedback loops).
enum SyntheticEventMarker {
    /// Arbitrary constant ("CMDX" in ASCII).
    private static let tag: Int64 = 0x434D_4458

    static func mark(_ event: CGEvent) {
        event.setIntegerValueField(.eventSourceUserData, value: tag)
    }

    static func isSynthetic(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == tag
    }
}
