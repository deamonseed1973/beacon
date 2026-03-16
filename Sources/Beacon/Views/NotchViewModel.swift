import AppKit
import Combine
import SwiftUI

@MainActor
final class NotchViewModel: ObservableObject {
    @Published var layout: NotchLayout
    @Published var isExpanded = false
    @Published var expandedContentMode: ExpandedPanelContentMode = .preview
    @Published var appName: String = ""
    @Published var appIcon: NSImage?
    @Published var report: AuditReport?
    @Published var annotatedScreenshot: NSImage?
    @Published var isScanning = false

    var exportAction: () -> Void = {}
    var captureAction: () -> Void = {}
    var previewAnnotatedScreenshotAction: () -> Void = {}
    var captureShortcut = ""
    var exportShortcut = ""
    var reportsShortcut = ""
    var toggleShortcut = ""

    init(layout: NotchLayout) {
        self.layout = layout
    }

    var healthScore: HealthScore {
        report?.healthScore ?? .good
    }

    var issueCount: Int {
        report?.issues.count ?? 0
    }

    var issues: [AccessibilityIssue] {
        report?.issues ?? []
    }
}
