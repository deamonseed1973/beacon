import AppKit
import Combine

/// Watches NSWorkspace for frontmost app changes.
final class AppMonitor: ObservableObject {
    @Published var currentApp: NSRunningApplication?

    private var cancellable: AnyCancellable?

    func start() {
        // Set initial value
        currentApp = NSWorkspace.shared.frontmostApplication

        cancellable = NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { notification -> NSRunningApplication? in
                notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] app in
                self?.currentApp = app
            }
    }

    func stop() {
        cancellable?.cancel()
        cancellable = nil
    }
}
