import CmdXCore
import Foundation

@MainActor
final class StubItemLocator: CutItemLocating {
    var frames: [CGRect] = []
    private(set) var requestedItems: [[URL]] = []

    func frames(of items: [URL]) async -> [CGRect] {
        requestedItems.append(items)
        return frames
    }
}

/// A locator whose search stays in progress until the test finishes it.
@MainActor
final class SuspendedItemLocator: CutItemLocating {
    private var continuation: CheckedContinuation<[CGRect], Never>?
    private(set) var requestCount = 0

    func frames(of items: [URL]) async -> [CGRect] {
        requestCount += 1
        return await withCheckedContinuation { continuation = $0 }
    }

    func waitUntilRequested() async {
        while continuation == nil {
            await Task.yield()
        }
    }

    func finish(with frames: [CGRect]) {
        continuation?.resume(returning: frames)
        continuation = nil
    }
}

@MainActor
final class SpyHighlighter: CutHighlighting {
    private(set) var shown: [[CGRect]] = []
    private(set) var hideCount = 0

    func show(_ frames: [CGRect]) { shown.append(frames) }
    func hide() { hideCount += 1 }
}
