import AppKit

struct RunningAppContext: Equatable, @unchecked Sendable {
    let processIdentifier: pid_t
    let bundleIdentifier: String
    let localizedName: String
    let icon: NSImage?

    init(processIdentifier: pid_t, bundleIdentifier: String, localizedName: String, icon: NSImage?) {
        self.processIdentifier = processIdentifier
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.icon = icon
    }

    init?(runningApplication: NSRunningApplication) {
        guard let bundleIdentifier = runningApplication.bundleIdentifier else { return nil }
        self.init(
            processIdentifier: runningApplication.processIdentifier,
            bundleIdentifier: bundleIdentifier,
            localizedName: runningApplication.localizedName ?? "Unknown",
            icon: runningApplication.icon
        )
    }
}
