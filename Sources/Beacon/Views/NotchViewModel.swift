import AppKit
import Combine
import SwiftUI

@MainActor
final class NotchViewModel: ObservableObject {
    @Published var layout: NotchLayout
    @Published var appName: String = ""
    @Published var appIcon: NSImage?
    @Published var report: AuditReport?
    @Published var annotatedScreenshot: NSImage?
    @Published var isScanning = false

    var exportAction: () -> Void = {}
    var captureAction: () -> Void = {}
    var captureShortcut = ""
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
}
