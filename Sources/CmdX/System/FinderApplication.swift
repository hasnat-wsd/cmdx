import AppKit

/// Identity of the Finder process.
enum FinderApplication {
    static let bundleIdentifier = "com.apple.finder"

    static var processIdentifier: pid_t? {
        NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .first?
            .processIdentifier
    }
}
