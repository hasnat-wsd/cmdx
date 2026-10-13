import ApplicationServices
import Foundation

/// Safely converts raw CoreFoundation values returned by the Accessibility
/// API into Swift types. Every cast is guarded by a CF type-ID check.
enum AXValueDecoder {
    static func element(_ value: CFTypeRef?) -> AXElement? {
        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return AXElement(raw: unsafeDowncast(value, to: AXUIElement.self))
    }

    static func elements(_ value: CFTypeRef?) -> [AXElement] {
        guard let array = value as? [AnyObject] else { return [] }
        return array.compactMap { element($0) }
    }

    static func string(_ value: CFTypeRef?) -> String? {
        value as? String
    }

    static func url(_ value: CFTypeRef?) -> URL? {
        switch value {
        case let url as URL:
            return url
        case let string as String:
            return URL(string: string)
        default:
            return nil
        }
    }

    static func point(_ value: CFTypeRef?) -> CGPoint? {
        var point = CGPoint.zero
        guard let axValue = axValue(value, of: .cgPoint), AXValueGetValue(axValue, .cgPoint, &point) else {
            return nil
        }
        return point
    }

    static func size(_ value: CFTypeRef?) -> CGSize? {
        var size = CGSize.zero
        guard let axValue = axValue(value, of: .cgSize), AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }
        return size
    }

    /// `AXUIElementCopyMultipleAttributeValues` reports per-attribute
    /// failures as `AXValue`s of type `.axError`.
    static func isError(_ value: CFTypeRef) -> Bool {
        axValue(value, of: .axError) != nil
    }

    private static func axValue(_ value: CFTypeRef?, of type: AXValueType) -> AXValue? {
        guard let value, CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        let axValue = unsafeDowncast(value, to: AXValue.self)
        return AXValueGetType(axValue) == type ? axValue : nil
    }
}
