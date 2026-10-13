import ApplicationServices
import Foundation

/// Everything the item search needs from one Accessibility node, fetched
/// in a single IPC round trip.
struct AXNodeSnapshot {
    private static let attributes: [String] = [
        kAXRoleAttribute,
        kAXChildrenAttribute,
        kAXVisibleRowsAttribute,
        kAXURLAttribute,
        kAXFilenameAttribute,
        kAXTitleAttribute,
        kAXValueAttribute,
        kAXPositionAttribute,
        kAXSizeAttribute
    ]

    /// Containers whose children may include thousands of off-screen rows.
    private static let rowContainerRoles: Set<String> = [kAXOutlineRole, kAXTableRole]

    let role: String?
    let url: URL?
    /// Candidate display names: filename, title and value, in that order.
    let labels: [String]
    let frame: CGRect?
    /// Children worth descending into (only visible rows for lists).
    let children: [AXElement]

    init(_ element: AXElement) {
        let values = element.values(Self.attributes)
        let role = AXValueDecoder.string(values[kAXRoleAttribute])

        self.role = role
        self.url = AXValueDecoder.url(values[kAXURLAttribute])
        self.labels = [kAXFilenameAttribute, kAXTitleAttribute, kAXValueAttribute]
            .compactMap { AXValueDecoder.string(values[$0]) }
            .filter { !$0.isEmpty }

        if let origin = AXValueDecoder.point(values[kAXPositionAttribute]),
           let size = AXValueDecoder.size(values[kAXSizeAttribute]) {
            self.frame = CGRect(origin: origin, size: size)
        } else {
            self.frame = nil
        }

        let visibleRows = AXValueDecoder.elements(values[kAXVisibleRowsAttribute])
        if let role, Self.rowContainerRoles.contains(role), !visibleRows.isEmpty {
            self.children = visibleRows
        } else {
            self.children = AXValueDecoder.elements(values[kAXChildrenAttribute])
        }
    }
}
