import AppKit

enum NotchChromeMetrics {
    static let compactMinWidth: CGFloat = 252
    static let compactMaxWidth: CGFloat = 315
    static let compactHeight: CGFloat = 54
    static let compactTopInsetFromCutoutBottom: CGFloat = -2
    static let expandedMinWidth: CGFloat = 412
    static let expandedMaxWidth: CGFloat = 448
    static let expandedHeight: CGFloat = 456
    static let compactToExpandedSpacing: CGFloat = 10
    static let fallbackAnchorWidth: CGFloat = 116
    static let fallbackAnchorHeight: CGFloat = 14
    static let compactOverflowTop: CGFloat = 14
    static let compactOverflowBottom: CGFloat = 24
    static let compactOverflowHorizontal: CGFloat = 16
    static let expandedOverflowTop: CGFloat = 12
    static let expandedOverflowBottom: CGFloat = 44
    static let expandedOverflowHorizontal: CGFloat = 22
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
    let contentFrame: CGRect
    let windowFrame: CGRect
    let compactTrayWidth: CGFloat

    var compactSize: CGSize { compactAnchorFrame.size }
    var expandedSize: CGSize { expandedFrame.size }
    var compactOriginInWindow: CGPoint {
        CGPoint(
            x: compactAnchorFrame.minX - windowFrame.minX,
            y: windowFrame.maxY - compactAnchorFrame.maxY
        )
    }
    var expandedOriginInWindow: CGPoint {
        CGPoint(
            x: expandedFrame.minX - windowFrame.minX,
            y: windowFrame.maxY - expandedFrame.maxY
        )
    }

    static func make(for screen: NSScreen, isExpanded: Bool) -> NotchLayout {
        make(for: ScreenMetrics(screen: screen), isExpanded: isExpanded)
    }

    static func make(for metrics: ScreenMetrics, isExpanded: Bool) -> NotchLayout {
        let cutoutFrame = cutoutFrame(for: metrics)
        let compactTrayWidth = min(
            max(cutoutFrame.width + 28, NotchChromeMetrics.compactMinWidth),
            NotchChromeMetrics.compactMaxWidth
        )

        let compactTop = cutoutFrame.minY + NotchChromeMetrics.compactTopInsetFromCutoutBottom
        let compactY = compactTop - NotchChromeMetrics.compactHeight
        let compactAnchorFrame = CGRect(
            x: cutoutFrame.midX - compactTrayWidth / 2,
            y: compactY,
            width: compactTrayWidth,
            height: NotchChromeMetrics.compactHeight
        )

        let expandedWidth = min(
            max(NotchChromeMetrics.expandedMinWidth, compactTrayWidth + 248),
            NotchChromeMetrics.expandedMaxWidth
        )
        let expandedFrame = CGRect(
            x: cutoutFrame.midX - expandedWidth / 2,
            y: compactY - NotchChromeMetrics.compactToExpandedSpacing - NotchChromeMetrics.expandedHeight,
            width: expandedWidth,
            height: NotchChromeMetrics.expandedHeight
        )

        let contentFrame = isExpanded ? compactAnchorFrame.union(expandedFrame) : compactAnchorFrame
        let compactOverflow = compactAnchorFrame.insetBy(
            dx: -NotchChromeMetrics.compactOverflowHorizontal,
            dy: 0
        ).offsetBy(dx: 0, dy: 0)
        let compactOverflowFrame = CGRect(
            x: compactOverflow.minX,
            y: compactAnchorFrame.minY - NotchChromeMetrics.compactOverflowBottom,
            width: compactOverflow.width,
            height: compactAnchorFrame.height
                + NotchChromeMetrics.compactOverflowTop
                + NotchChromeMetrics.compactOverflowBottom
        )

        let overflowBounds: CGRect
        if isExpanded {
            let expandedOverflowFrame = CGRect(
                x: expandedFrame.minX - NotchChromeMetrics.expandedOverflowHorizontal,
                y: expandedFrame.minY - NotchChromeMetrics.expandedOverflowBottom,
                width: expandedFrame.width + (NotchChromeMetrics.expandedOverflowHorizontal * 2),
                height: expandedFrame.height
                    + NotchChromeMetrics.expandedOverflowTop
                    + NotchChromeMetrics.expandedOverflowBottom
            )
            overflowBounds = compactOverflowFrame.union(expandedOverflowFrame)
        } else {
            overflowBounds = compactOverflowFrame
        }

        let windowFrame = overflowBounds.integral

        return NotchLayout(
            cutoutFrame: cutoutFrame,
            compactAnchorFrame: compactAnchorFrame,
            expandedFrame: expandedFrame,
            contentFrame: contentFrame,
            windowFrame: windowFrame,
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
