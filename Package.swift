// swift-tools-version:6.0
import PackageDescription

// Zero third-party dependencies: only Apple system frameworks are used.
let package = Package(
    name: "CmdX",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "CmdX", targets: ["CmdX"])
    ],
    targets: [
        // Pure, platform-agnostic business logic (Foundation only, fully unit tested).
        .target(name: "CmdXCore"),
        // AppKit / CoreGraphics / Accessibility adapters and the menu bar UI.
        .executableTarget(name: "CmdX", dependencies: ["CmdXCore"]),
        .testTarget(name: "CmdXCoreTests", dependencies: ["CmdXCore"])
    ]
)
