import AppKit
import Combine

struct InspectionSnapshot: @unchecked Sendable {
    let report: AuditReport
    let annotatedScreenshot: NSImage?
}

@MainActor
final class InspectionCoordinator: ObservableObject {
    typealias ScanHandler = @Sendable (RunningAppContext) async -> InspectionSnapshot?
    typealias ExportHandler = (AuditReport, NSImage?) throws -> Void

    @Published private(set) var inspectedApp: RunningAppContext?
    @Published private(set) var latestReport: AuditReport?
    @Published private(set) var latestAnnotatedScreenshot: NSImage?
    @Published private(set) var isScanning = false

    private let beaconBundleIdentifier: String
    private let scanHandler: ScanHandler
    private let exportHandler: ExportHandler
    private var scanGeneration = 0

    init(
        beaconBundleIdentifier: String,
        scanHandler: @escaping ScanHandler,
        exportHandler: @escaping ExportHandler
    ) {
        self.beaconBundleIdentifier = beaconBundleIdentifier
        self.scanHandler = scanHandler
        self.exportHandler = exportHandler
    }

    func shouldInspect(_ app: RunningAppContext) -> Bool {
        app.bundleIdentifier != beaconBundleIdentifier
    }

    func handleFrontmostApp(_ app: RunningAppContext) {
        guard shouldInspect(app) else { return }
        inspectedApp = app
        latestReport = nil
        latestAnnotatedScreenshot = nil
        requestScan(for: app)
    }

    func captureCurrentReport() {
        guard let inspectedApp else { return }
        requestScan(for: inspectedApp)
    }

    func exportCurrentReport() throws {
        guard let latestReport else { return }
        try exportHandler(latestReport, latestAnnotatedScreenshot)
    }

    private func requestScan(for app: RunningAppContext) {
        scanGeneration += 1
        let generation = scanGeneration
        isScanning = true

        Task { [scanHandler] in
            let snapshot = await scanHandler(app)
            await MainActor.run {
                guard generation == self.scanGeneration else { return }
                guard self.inspectedApp?.processIdentifier == app.processIdentifier else { return }
                self.latestReport = snapshot?.report
                self.latestAnnotatedScreenshot = snapshot?.annotatedScreenshot
                self.isScanning = false
            }
        }
    }
}
