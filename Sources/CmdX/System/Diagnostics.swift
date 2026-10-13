import Foundation
import os

/// Unified-logging channels. View them with:
/// `log stream --level debug --predicate 'subsystem == "com.wsd.cmdx"'`
enum Diagnostics {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.wsd.cmdx"

    static let cut = Logger(subsystem: subsystem, category: "cut")
    static let focus = Logger(subsystem: subsystem, category: "focus")
}
