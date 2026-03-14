import AppKit
import Combine

/// Watches NSWorkspace for frontmost app changes.
final class AppMonitor: ObservableObject {
    @Published var currentApp: NSRunningApplication?

    private let excludedBundleIdentifiers: Set<String>
    private var cancellable: AnyCancellable?

    init(excludedBundleIdentifiers: Set<String> = []) {
        self.excludedBundleIdentifiers = excludedBundleIdentifiers
    }

    func start() {
        // Set initial value
        currentApp = filteredApp(NSWorkspace.shared.frontmostApplication)

        cancellable = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { notification -> NSRunningApplication? in
                notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            }
            .map { [excludedBundleIdentifiers] app in
                guard let bundleIdentifier = app.bundleIdentifier else { return nil }
                return excludedBundleIdentifiers.contains(bundleIdentifier) ? nil : app
            }
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] app in
                self?.currentApp = app
            }
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
    }

    private func filteredApp(_ app: NSRunningApplication?) -> NSRunningApplication? {
        guard let app, let bundleIdentifier = app.bundleIdentifier else { return nil }
        return excludedBundleIdentifiers.contains(bundleIdentifier) ? nil : app
    }
}
