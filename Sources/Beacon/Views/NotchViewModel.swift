import AppKit
import Combine
import SwiftUI

@MainActor
final class NotchViewModel: ObservableObject {
    @Published var appName: String = ""
    @Published var appIcon: NSImage?
    @Published var report: AuditReport?
    @Published var annotatedScreenshot: NSImage?

    var healthScore: HealthScore {
        report?.healthScore ?? .good
    }

    var issueCount: Int {
        report?.issues.count ?? 0
    }

    var isScanning: Bool {
        report == nil && !appName.isEmpty
    }
}
