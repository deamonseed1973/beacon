import AppKit

final class NotchWindow: NSWindow {
    private let notchRect: CGRect

    init(screen: NSScreen) {
        let frame = notchFrame(on: screen)
        self.notchRect = frame

        // Window is taller than the notch to accommodate expanded state
        let expandedHeight: CGFloat = 260
        let windowWidth = max(frame.width, 460)
        let windowFrame = CGRect(
            x: frame.midX - windowWidth / 2,
            y: frame.minY - expandedHeight,
            width: windowWidth,
            height: expandedHeight + frame.height
        )

        super.init(
            contentRect: windowFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        self.level = .statusBar + 1
        self.collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
    }
}
