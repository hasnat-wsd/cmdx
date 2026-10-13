import CmdXCore
import Foundation

@MainActor
final class StubItemLocator: CutItemLocating {
    var frames: [CGRect] = []
    private(set) var requestedItems: [[URL]] = []

    func frames(of items: [URL]) -> [CGRect] {
        requestedItems.append(items)
        return frames
    }
}

@MainActor
final class SpyHighlighter: CutHighlighting {
    private(set) var shown: [[CGRect]] = []
    private(set) var hideCount = 0

    func show(_ frames: [CGRect]) { shown.append(frames) }
    func hide() { hideCount += 1 }
}
