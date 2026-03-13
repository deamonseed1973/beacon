import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchWindow: NotchWindow?
    private var appMonitor: AppMonitor?
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
        let monitor = AppMonitor()
        self.appMonitor = monitor

        let viewModel = NotchViewModel()

        let hostingController = NotchHostingController(viewModel: viewModel)
        window.contentViewController = hostingController
        window.orderFrontRegardless()

        monitor.$currentApp
            .compactMap { $0 }
            .removeDuplicates { $0.processIdentifier == $1.processIdentifier }
            .sink { [weak viewModel] runningApp in
                guard let viewModel = viewModel else { return }
                let appName = runningApp.localizedName ?? "Unknown"
                let bundleID = runningApp.bundleIdentifier ?? ""

                viewModel.appName = appName
                viewModel.appIcon = runningApp.icon

                Task {
                    let report = await scanner.scan(app: runningApp)
                    await MainActor.run {
                        viewModel.report = report
                    }
                }
            }
            .store(in: &cancellables)

        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        appMonitor?.stop()
    }
}
