import Foundation
import CoreGraphics

struct AuditReport: Codable {
    let appName: String
    let bundleID: String
    let timestamp: Date
    let totalElements: Int
    let issues: [AccessibilityIssue]

    var healthScore: HealthScore {
        if issues.isEmpty { return .good }
        let ratio = Double(issues.count) / max(Double(totalElements), 1.0)
        if ratio < 0.05 { return .warning }
        return .critical
    }
}

struct AccessibilityIssue: Codable {
    let index: Int
    let elementRole: String
    let axText: String
    let visualText: String
    let frame: CodableRect
    let issueType: IssueType
}

/// Codable wrapper for CGRect since CoreGraphics types aren't Codable.
struct CodableRect: Codable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    init(_ rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

enum IssueType: String, Codable {
    case gap
    case mismatch
}

enum HealthScore: String, Codable {
    case good
    case warning
    case critical
}
