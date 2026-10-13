import CmdXCore
import CoreGraphics

/// Observes key-down events system-wide and lets a handler decide whether
/// each one is delivered or swallowed.
///
/// Privacy: keystrokes are inspected in memory only to recognise the
/// shortcuts CmdX supports. Nothing is logged, stored or transmitted.
@MainActor
final class EventTapMonitor {
    typealias Handler = @MainActor (KeyStroke) -> EventDecision

    private let handler: Handler
    private var machPort: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    init(handler: @escaping Handler) {
        self.handler = handler
    }

    var isRunning: Bool {
        machPort != nil
    }

    /// Installs the event tap. Fails (returns `false`) until the app has
    /// been granted Accessibility access.
    @discardableResult
    func start() -> Bool {
        guard machPort == nil else { return true }

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        // Attached to the main run loop, so callbacks are on the main thread.
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)

        machPort = port
        runLoopSource = source
        return true
    }

    func stop() {
        if let machPort {
            CGEvent.tapEnable(tap: machPort, enable: false)
            CFMachPortInvalidate(machPort)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        machPort = nil
        runLoopSource = nil
    }

    /// Re-enables the tap after macOS disabled it for responding too slowly.
    fileprivate func recoverFromTimeout() {
        if let machPort { CGEvent.tapEnable(tap: machPort, enable: true) }
    }

    /// Returns `true` when the key press must be swallowed.
    fileprivate func shouldConsume(_ stroke: KeyStroke) -> Bool {
        handler(stroke) == .consume
    }
}

/// C-compatible trampoline into `EventTapMonitor`.
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else { return Unmanaged.passUnretained(event) }
    let monitor = Unmanaged<EventTapMonitor>.fromOpaque(userInfo).takeUnretainedValue()

    // The tap's run loop source lives on the main run loop (see `start()`).
    switch type {
    case .tapDisabledByTimeout:
        MainActor.assumeIsolated { monitor.recoverFromTimeout() }
    case .keyDown where !SyntheticEventMarker.isSynthetic(event):
        // Map to a Sendable value before crossing into main-actor code.
        let stroke = KeyStrokeMapper.keyStroke(from: event)
        if MainActor.assumeIsolated({ monitor.shouldConsume(stroke) }) {
            return nil
        }
    default:
        break
    }
    return Unmanaged.passUnretained(event)
}
