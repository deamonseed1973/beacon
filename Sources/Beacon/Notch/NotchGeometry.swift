import AppKit

enum NotchChromeMetrics {
    static let bridgeMinWidth: CGFloat = 72
    static let bridgeMaxWidth: CGFloat = 132
    static let bridgeHeight: CGFloat = 14
    static let compactMinWidth: CGFloat = 112
    static let compactMaxWidth: CGFloat = 148
    static let compactHeight: CGFloat = 38
    static let compactOverlap: CGFloat = 8
    static let compactBridgeOverlap: CGFloat = 6
    static let expandedWidth: CGFloat = 208
    static let expandedHeight: CGFloat = 176
    static let compactToExpandedSpacing: CGFloat = 8
    static let fallbackAnchorWidth: CGFloat = 108
    static let fallbackAnchorHeight: CGFloat = 14
}

struct ScreenMetrics {
    let frame: CGRect
    let safeAreaTop: CGFloat
    let auxiliaryTopLeftWidth: CGFloat?
    let auxiliaryTopRightWidth: CGFloat?

    init(
        frame: CGRect,
        safeAreaTop: CGFloat,
        auxiliaryTopLeftWidth: CGFloat?,
        auxiliaryTopRightWidth: CGFloat?
    ) {
        self.frame = frame
        self.safeAreaTop = safeAreaTop
        self.auxiliaryTopLeftWidth = auxiliaryTopLeftWidth
        self.auxiliaryTopRightWidth = auxiliaryTopRightWidth
    }

    init(screen: NSScreen) {
        frame = screen.frame
        safeAreaTop = screen.safeAreaInsets.top
        auxiliaryTopLeftWidth = screen.auxiliaryTopLeftArea?.width
        auxiliaryTopRightWidth = screen.auxiliaryTopRightArea?.width
    }
}

struct NotchLayout {
    let cutoutFrame: CGRect
    let compactAnchorFrame: CGRect
    let expandedFrame: CGRect
    let windowFrame: CGRect
    let bridgeWidth: CGFloat
    let compactTrayWidth: CGFloat

    var compactSize: CGSize { compactAnchorFrame.size }
    var expandedSize: CGSize { expandedFrame.size }

    static func make(for screen: NSScreen, isExpanded: Bool) -> NotchLayout {
        make(for: ScreenMetrics(screen: screen), isExpanded: isExpanded)
    }

    static func make(for metrics: ScreenMetrics, isExpanded: Bool) -> NotchLayout {
        let screenFrame = metrics.frame
        let cutoutFrame = cutoutFrame(for: metrics)
        let bridgeWidth = min(
            max(cutoutFrame.width - 12, NotchChromeMetrics.bridgeMinWidth),
            NotchChromeMetrics.bridgeMaxWidth
        )
        let compactTrayWidth = min(
            max(cutoutFrame.width + 20, NotchChromeMetrics.compactMinWidth),
            NotchChromeMetrics.compactMaxWidth
        )

        let compactY = cutoutFrame.minY - NotchChromeMetrics.compactHeight + NotchChromeMetrics.compactOverlap
        let compactAnchorFrame = CGRect(
            x: cutoutFrame.midX - compactTrayWidth / 2,
            y: compactY,
            width: compactTrayWidth,
            height: screenFrame.maxY - compactY
        )

        let expandedWidth = max(NotchChromeMetrics.expandedWidth, compactTrayWidth + 60)
        let expandedFrame = CGRect(
            x: cutoutFrame.midX - expandedWidth / 2,
            y: compactY - NotchChromeMetrics.compactToExpandedSpacing - NotchChromeMetrics.expandedHeight,
            width: expandedWidth,
            height: NotchChromeMetrics.expandedHeight
        )

        let visibleFrame = isExpanded ? compactAnchorFrame.union(expandedFrame) : compactAnchorFrame
        let windowFrame = CGRect(
            x: visibleFrame.minX,
            y: visibleFrame.minY,
            width: visibleFrame.width,
            height: screenFrame.maxY - visibleFrame.minY
        )

        return NotchLayout(
            cutoutFrame: cutoutFrame,
            compactAnchorFrame: compactAnchorFrame,
            expandedFrame: expandedFrame,
            windowFrame: windowFrame,
            bridgeWidth: bridgeWidth,
            compactTrayWidth: compactTrayWidth
        )
    }

    private static func cutoutFrame(for metrics: ScreenMetrics) -> CGRect {
        let screenFrame = metrics.frame

        if let topLeft = metrics.auxiliaryTopLeftWidth,
           let topRight = metrics.auxiliaryTopRightWidth,
           metrics.safeAreaTop > 0
        {
            let notchWidth = screenFrame.width - topLeft - topRight + 4
            let notchHeight = max(metrics.safeAreaTop, 24)
            let x = screenFrame.minX + topLeft - 2
            let y = screenFrame.maxY - notchHeight
            return CGRect(x: x, y: y, width: notchWidth, height: notchHeight)
        }

        return CGRect(
            x: screenFrame.midX - NotchChromeMetrics.fallbackAnchorWidth / 2,
            y: screenFrame.maxY - NotchChromeMetrics.fallbackAnchorHeight,
            width: NotchChromeMetrics.fallbackAnchorWidth,
            height: NotchChromeMetrics.fallbackAnchorHeight
        )
    }
}

/// Calculates the notch frame on a given screen.
func notchFrame(on screen: NSScreen) -> CGRect {
    NotchLayout.make(for: screen, isExpanded: false).cutoutFrame
}

/// Whether the screen has a physical notch cutout.
func hasNotch(on screen: NSScreen) -> Bool {
    screen.safeAreaInsets.top > 0
}
