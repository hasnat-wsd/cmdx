import ApplicationServices
import Foundation

/// Walks a Finder Accessibility subtree and collects the on-screen frames
/// of nodes accepted by a `FinderItemMatcher`.
///
/// The walk is bounded by node count, depth and wall-clock time so a huge
/// folder or a busy Finder can never stall the app's main thread.
@MainActor
struct AXTreeSearcher {
    private static let skippedRoles: Set<String> = [kAXToolbarRole, kAXMenuBarRole]
    private static let maxNodes = 2_500
    private static let maxDepth = 16
    private static let timeBudget: TimeInterval = 0.06

    let matcher: FinderItemMatcher

    func frames(in root: AXElement) -> [CGRect] {
        var walk = Walk(deadline: Date().addingTimeInterval(Self.timeBudget))
        visit(root, clip: .infinite, rowFrame: nil, depth: 0, walk: &walk)
        return walk.frames
    }

    private func visit(_ element: AXElement, clip: CGRect, rowFrame: CGRect?, depth: Int, walk: inout Walk) {
        guard depth <= Self.maxDepth, walk.nextNode(limit: Self.maxNodes) else { return }

        let node = AXNodeSnapshot(element)
        guard let role = node.role, !Self.skippedRoles.contains(role) else { return }

        // Content scrolled out of a scroll area is reported with real
        // coordinates outside it; clip so we never paint over toolbars.
        var clip = clip
        if role == kAXScrollAreaRole, let frame = node.frame {
            clip = clip.intersection(frame)
        }
        // In list view, fade the whole row rather than just the name cell.
        let rowFrame = role == kAXRowRole ? node.frame : rowFrame

        if matcher.matches(node), let frame = rowFrame ?? node.frame {
            walk.add(frame.intersection(clip))
        }
        for child in node.children {
            visit(child, clip: clip, rowFrame: rowFrame, depth: depth + 1, walk: &walk)
        }
    }
}

/// Mutable bookkeeping for a single bounded walk.
private struct Walk {
    let deadline: Date
    private(set) var frames: [CGRect] = []
    private var visited = 0

    init(deadline: Date) {
        self.deadline = deadline
    }

    mutating func nextNode(limit: Int) -> Bool {
        visited += 1
        return visited <= limit && Date() < deadline
    }

    mutating func add(_ frame: CGRect) {
        guard !frame.isNull, !frame.isEmpty, !frames.contains(frame) else { return }
        frames.append(frame)
    }
}
