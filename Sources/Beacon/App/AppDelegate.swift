import AppKit
import Combine
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchWindow: NotchWindow?
    private var appMonitor: AppMonitor?
    private var inspectionCoordinator: InspectionCoordinator?
    private var hotKeys: [HotKey] = []
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let screen = NSScreen.main else {
            NSLog("Beacon: No main screen found")
            NSApp.terminate(nil)
            return
        }

        let window = NotchWindow(screen: screen)
        self.notchWindow = window

        let scanner = AccessibilityScanner()
        let annotator = ScreenAnnotator()
        let exporter = ReportExporter()
        let beaconBundleIdentifier = Bundle.main.bundleIdentifier ?? "com.beacon.app"
        let monitor = AppMonitor(excludedBundleIdentifiers: [beaconBundleIdentifier])
        self.appMonitor = monitor

        let inspectionCoordinator = InspectionCoordinator(
            beaconBundleIdentifier: beaconBundleIdentifier,
            scanHandler: { runningApp in
                guard let app = NSRunningApplication(processIdentifier: runningApp.processIdentifier) else {
                    return nil
                }

                let report = await scanner.scan(app: app)
                let annotatedScreenshot: NSImage?
                if let screenshot = ElementCapture.captureFullScreen() {
                    annotatedScreenshot = annotator.annotate(screenshot: screenshot, issues: report.issues)
                } else {
                    annotatedScreenshot = nil
                }
                return InspectionSnapshot(report: report, annotatedScreenshot: annotatedScreenshot)
            },
            exportHandler: { report, annotatedImage in
                try exporter.export(report: report, annotatedImage: annotatedImage)
            }
        )
        self.inspectionCoordinator = inspectionCoordinator

        let viewModel = NotchViewModel(layout: window.layout)
        window.onLayoutChange = { [weak viewModel] layout in
            viewModel?.layout = layout
        }
        viewModel.exportAction = { [weak inspectionCoordinator] in
            do {
                try inspectionCoordinator?.exportCurrentReport()
            } catch {
                NSLog("Beacon: Export failed: \(error)")
            }
        }
        viewModel.captureAction = { [weak inspectionCoordinator] in
            inspectionCoordinator?.captureCurrentReport()
        }
        viewModel.captureShortcut = hotKeyDisplayString(
            keyCode: UInt32(kVK_ANSI_A),
            modifiers: [.option, .shift]
        )
        viewModel.toggleShortcut = hotKeyDisplayString(
            keyCode: UInt32(kVK_ANSI_B),
            modifiers: [.option, .shift]
        )

        let hostingController = NotchHostingController(
            viewModel: viewModel,
            onExpansionChanged: { [weak window] isExpanded in
                window?.setExpanded(isExpanded)
            }
        )
        window.contentViewController = hostingController
        window.orderFrontRegardless()

        monitor.$currentApp
            .compactMap { $0 }
            .removeDuplicates { $0.processIdentifier == $1.processIdentifier }
            .compactMap(RunningAppContext.init)
            .sink { [weak inspectionCoordinator] runningApp in
                inspectionCoordinator?.handleFrontmostApp(runningApp)
            }
            .store(in: &cancellables)

        inspectionCoordinator.$inspectedApp
            .sink { [weak viewModel] app in
                viewModel?.appName = app?.localizedName ?? ""
                viewModel?.appIcon = app?.icon
            }
            .store(in: &cancellables)

        inspectionCoordinator.$latestReport
            .sink { [weak viewModel] report in
                viewModel?.report = report
            }
            .store(in: &cancellables)

        inspectionCoordinator.$latestAnnotatedScreenshot
            .sink { [weak viewModel] screenshot in
                viewModel?.annotatedScreenshot = screenshot
            }
            .store(in: &cancellables)

        inspectionCoordinator.$isScanning
            .sink { [weak viewModel] isScanning in
                viewModel?.isScanning = isScanning
            }
            .store(in: &cancellables)

        registerHotKeys(with: inspectionCoordinator, window: window)
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotKeyCenter.shared.unregisterAllHotKeys()
        hotKeys.removeAll()
        appMonitor?.stop()
    }

    private func registerHotKeys(with inspectionCoordinator: InspectionCoordinator, window: NotchWindow) {
        if let captureHotKey = HotKeyCenter.shared.registerHotKey(
            keyCode: UInt32(kVK_ANSI_A),
            modifierFlags: [.option, .shift]
        ) { _ in
            Task { @MainActor in
                inspectionCoordinator.captureCurrentReport()
            }
        } {
            hotKeys.append(captureHotKey)
        }

        if let toggleHotKey = HotKeyCenter.shared.registerHotKey(
            keyCode: UInt32(kVK_ANSI_B),
            modifierFlags: [.option, .shift]
        ) { _ in
            Task { @MainActor in
                window.toggleVisibility()
            }
        } {
            hotKeys.append(toggleHotKey)
        }
    }
}
