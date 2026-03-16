import ApplicationServices
import AppKit

/// Lightweight wrapper around AXUIElement providing typed access to common attributes.
/// Inspired by AXray's visitor-pattern approach to AX tree walking.
struct AXElement: @unchecked Sendable {
    let underlying: AXUIElement

    var role: String? {
        attribute(.role)
    }

    var title: String? {
        attribute(.title)
    }

    var value: String? {
        guard let val: AnyObject = attribute(.value) else { return nil }
        return val as? String
    }

    var roleDescription: String? {
        attribute(.roleDescription)
    }

    var label: String? {
        attribute(.description)
    }

    var frame: CGRect? {
        guard let position: CGPoint = attributeValue(.position),
              let size: CGSize = attributeValue(.size) else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    var children: [AXElement] {
        guard let kids: [AXUIElement] = attribute(.children) else { return [] }
        return kids.map { AXElement(underlying: $0) }
    }

    var focusedWindow: AXElement? {
        guard let window: AXUIElement = attribute(.focusedWindow) else { return nil }
        return AXElement(underlying: window)
    }

    /// The combined text content of this element (title, value, label).
    var textContent: String {
        [title, value, label].compactMap { $0 }.joined(separator: " ").trimmingCharacters(in: .whitespaces)
    }

    /// Whether this element has any user-visible text via AX attributes.
    var hasText: Bool {
        !textContent.isEmpty
    }

    // MARK: - Private helpers

    private func attribute<T>(_ attr: NSAccessibility.Attribute) -> T? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(underlying, attr.rawValue as CFString, &value)
        guard result == .success else { return nil }
        return value as? T
    }

    private func attributeValue<T>(_ attr: NSAccessibility.Attribute) -> T? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(underlying, attr.rawValue as CFString, &value)
        guard result == .success, let axValue = value else { return nil }

        if T.self == CGPoint.self {
            var point = CGPoint.zero
            if AXValueGetValue(axValue as! AXValue, .cgPoint, &point) {
                return point as? T
            }
        } else if T.self == CGSize.self {
            var size = CGSize.zero
            if AXValueGetValue(axValue as! AXValue, .cgSize, &size) {
                return size as? T
            }
        }
        return nil
    }
}
