import ApplicationServices
import Foundation

/// Thin, type-safe wrapper around `AXUIElement` attribute access.
struct AXElement {
    enum Lookup {
        case value(CFTypeRef)
        case noValue
        case failure
    }

    let raw: AXUIElement

    static func application(pid: pid_t) -> AXElement {
        AXElement(raw: AXUIElementCreateApplication(pid))
    }

    /// Caps how long any Accessibility call from this process may block
    /// when the target application is busy or hung.
    static func setGlobalMessagingTimeout(_ seconds: Float) {
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), seconds)
    }

    func lookup(_ attribute: String) -> Lookup {
        var value: CFTypeRef?
        switch AXUIElementCopyAttributeValue(raw, attribute as CFString, &value) {
        case .success:
            return value.map(Lookup.value) ?? .noValue
        case .noValue:
            return .noValue
        default:
            return .failure
        }
    }

    func value(_ attribute: String) -> CFTypeRef? {
        guard case .value(let value) = lookup(attribute) else { return nil }
        return value
    }

    /// Fetches several attributes in a single IPC round trip. Attributes
    /// that are missing or fail are simply absent from the result.
    func values(_ attributes: [String]) -> [String: CFTypeRef] {
        var values: CFArray?
        let status = AXUIElementCopyMultipleAttributeValues(
            raw, attributes as CFArray, AXCopyMultipleAttributeOptions(rawValue: 0), &values
        )
        guard status == .success, let array = values as? [AnyObject] else { return [:] }

        var result: [String: CFTypeRef] = [:]
        for (attribute, value) in zip(attributes, array) where !AXValueDecoder.isError(value) {
            result[attribute] = value
        }
        return result
    }

    func string(_ attribute: String) -> String? {
        AXValueDecoder.string(value(attribute))
    }

    func element(_ attribute: String) -> AXElement? {
        AXValueDecoder.element(value(attribute))
    }

    func elements(_ attribute: String) -> [AXElement] {
        AXValueDecoder.elements(value(attribute))
    }

    func url(_ attribute: String) -> URL? {
        AXValueDecoder.url(value(attribute))
    }

    var role: String? {
        string(kAXRoleAttribute)
    }

    /// Whether `attribute` can be written, or `nil` if that cannot be determined.
    func isSettable(_ attribute: String) -> Bool? {
        var settable = DarwinBoolean(false)
        guard AXUIElementIsAttributeSettable(raw, attribute as CFString, &settable) == .success else {
            return nil
        }
        return settable.boolValue
    }
}
