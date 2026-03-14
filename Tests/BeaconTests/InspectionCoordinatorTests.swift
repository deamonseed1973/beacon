import AppKit
import Testing
@testable import Beacon

@MainActor
struct InspectionCoordinatorTests {
    @Test("Beacon activation is ignored as an inspected app")
    func ignoresBeaconActivation() {
        let coordinator = InspectionCoordinator(
            beaconBundleIdentifier: "com.example.beacon",
            scanHandler: { _ in nil },
            exportHandler: { _, _ in }
        )

        let beaconApp = RunningAppContext(
            processIdentifier: 100,
            bundleIdentifier: "com.example.beacon",
            localizedName: "Beacon",
            icon: nil
        )

        coordinator.handleFrontmostApp(beaconApp)

        #expect(coordinator.inspectedApp == nil)
        #expect(coordinator.latestReport == nil)
    }

    @Test("Last non-Beacon app remains the inspected app")
    func preservesLastTrackedApp() {
        let coordinator = InspectionCoordinator(
            beaconBundleIdentifier: "com.example.beacon",
            scanHandler: { _ in nil },
            exportHandler: { _, _ in }
        )
        let finder = RunningAppContext(
            processIdentifier: 200,
            bundleIdentifier: "com.apple.finder",
            localizedName: "Finder",
            icon: nil
        )
        let beaconApp = RunningAppContext(
            processIdentifier: 100,
            bundleIdentifier: "com.example.beacon",
            localizedName: "Beacon",
            icon: nil
        )

        coordinator.handleFrontmostApp(finder)
        coordinator.handleFrontmostApp(beaconApp)

        #expect(coordinator.inspectedApp == finder)
    }

    @Test("Manual capture rescans the inspected app")
    func manualCaptureUsesInspectedApp() async {
        let tracker = ScanTracker()
        let coordinator = InspectionCoordinator(
            beaconBundleIdentifier: "com.example.beacon",
            scanHandler: { app in
                await tracker.record(app.processIdentifier)
                return InspectionSnapshot(
                    report: AuditReport(
                        appName: app.localizedName,
                        bundleID: app.bundleIdentifier,
                        timestamp: .now,
                        totalElements: 1,
                        issues: []
                    ),
                    annotatedScreenshot: nil
                )
            },
            exportHandler: { _, _ in }
        )
        let app = RunningAppContext(
            processIdentifier: 300,
            bundleIdentifier: "com.apple.TextEdit",
            localizedName: "TextEdit",
            icon: nil
        )

        coordinator.handleFrontmostApp(app)
        coordinator.captureCurrentReport()
        try? await Task.sleep(for: .milliseconds(50))

        let recordedPIDs = await tracker.recordedPIDs
        #expect(recordedPIDs == [300, 300])
    }
}

actor ScanTracker {
    private(set) var recordedPIDs: [pid_t] = []

    func record(_ pid: pid_t) {
        recordedPIDs.append(pid)
    }
}
