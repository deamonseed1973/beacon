import AppKit

@MainActor
final class NotchWindow: NSWindow {
    private(set) var layout: NotchLayout
    private var currentScreen: NSScreen
    private var isExpanded = false
    private var screenObserver: NSObjectProtocol?
    private var localEventMonitor: Any?
    private var globalMouseMonitor: Any?
    private(set) var isOverlayVisible = true

    var onLayoutChange: ((NotchLayout) -> Void)?
    var onExpandedStateChange: ((Bool) -> Void)?

    init(screen: NSScreen) {
        currentScreen = screen
        layout = NotchLayout.make(for: screen, isExpanded: false)

        super.init(
            contentRect: layout.windowFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        configureWindow()
        startObservingScreens()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
        }
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
        }
    }

    func setExpanded(_ expanded: Bool) {
        guard expanded != isExpanded else { return }
        isExpanded = expanded
        onExpandedStateChange?(expanded)
        updateLayout(for: currentScreen, isExpanded: expanded, animated: true)
    }

    func toggleVisibility() {
        if isOverlayVisible {
            orderOut(nil)
        } else {
            setFrame(layout.windowFrame, display: true)
            orderFrontRegardless()
        }
        isOverlayVisible.toggle()
    }

    func updateLayout(for screen: NSScreen, isExpanded: Bool) {
        updateLayout(for: screen, isExpanded: isExpanded, animated: false)
    }

    private func configureWindow() {
        level = .statusBar + 1
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        acceptsMouseMovedEvents = true
        startObservingDismissEvents()
    }

    override var canBecomeKey: Bool { false }

    override var canBecomeMain: Bool { false }

    private func startObservingScreens() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let nextScreen = NSScreen.main ?? self.currentScreen
                self.updateLayout(for: nextScreen, isExpanded: self.isExpanded, animated: false)
            }
        }
    }

    private func updateLayout(for screen: NSScreen, isExpanded: Bool, animated: Bool) {
        currentScreen = screen
        layout = NotchLayout.make(for: screen, isExpanded: isExpanded)
        onLayoutChange?(layout)

        let applyFrame = {
            self.setFrame(self.layout.windowFrame, display: true)
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.animator().setFrame(self.layout.windowFrame, display: true)
            }
        } else {
            applyFrame()
        }
    }

    private func startObservingDismissEvents() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown]
        ) { [weak self] event in
            guard let self else { return event }
            guard self.isExpanded else { return event }

            switch event.type {
            case .keyDown:
                if event.keyCode == 53 {
                    self.setExpanded(false)
                    return nil
                }
            case .leftMouseDown, .rightMouseDown, .otherMouseDown:
                if let window = event.window, window === self {
                    return event
                }
                if !self.frame.contains(event.locationInWindow) {
                    self.setExpanded(false)
                }
            default:
                break
            }

            return event
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] event in
            guard let self, self.isExpanded else { return }
            if !self.frame.contains(event.locationInWindow) {
                Task { @MainActor [weak self] in
                    self?.setExpanded(false)
                }
            }
        }
    }
}
