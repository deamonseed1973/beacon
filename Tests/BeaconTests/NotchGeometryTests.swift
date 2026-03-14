import CoreGraphics
import Testing
@testable import Beacon

struct NotchGeometryTests {
    @Test("Builds a physical-notch anchored layout")
    func physicalNotchLayout() {
        let metrics = ScreenMetrics(
            frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            safeAreaTop: 37,
            auxiliaryTopLeftWidth: 664,
            auxiliaryTopRightWidth: 664
        )

        let layout = NotchLayout.make(for: metrics, isExpanded: true)

        #expect(layout.cutoutFrame.width == 188)
        #expect(layout.cutoutFrame.height == 37)
        #expect(layout.cutoutFrame.midX == 756)
        #expect(layout.compactAnchorFrame.maxY == 982)
        #expect(layout.expandedFrame.midX == layout.cutoutFrame.midX)
        #expect(layout.windowFrame.minY == layout.expandedFrame.minY)
        #expect(layout.windowFrame.maxY == 982)
    }

    @Test("Falls back to a centred anchor on non-notched screens")
    func fallbackLayout() {
        let metrics = ScreenMetrics(
            frame: CGRect(x: 100, y: 50, width: 1440, height: 900),
            safeAreaTop: 0,
            auxiliaryTopLeftWidth: nil,
            auxiliaryTopRightWidth: nil
        )

        let layout = NotchLayout.make(for: metrics, isExpanded: false)

        #expect(layout.cutoutFrame.width == NotchChromeMetrics.fallbackAnchorWidth)
        #expect(layout.cutoutFrame.height == NotchChromeMetrics.fallbackAnchorHeight)
        #expect(layout.cutoutFrame.midX == metrics.frame.midX)
        #expect(layout.windowFrame.minY == layout.compactAnchorFrame.minY)
        #expect(layout.windowFrame.maxY == metrics.frame.maxY)
    }

    @Test("Expanded and compact frames remain centre-aligned")
    func centreAlignment() {
        let metrics = ScreenMetrics(
            frame: CGRect(x: 0, y: 0, width: 1728, height: 1117),
            safeAreaTop: 38,
            auxiliaryTopLeftWidth: 770,
            auxiliaryTopRightWidth: 770
        )

        let compactLayout = NotchLayout.make(for: metrics, isExpanded: false)
        let expandedLayout = NotchLayout.make(for: metrics, isExpanded: true)

        #expect(compactLayout.windowFrame.width == compactLayout.compactAnchorFrame.width)
        #expect(expandedLayout.windowFrame.width == expandedLayout.expandedFrame.width)
        #expect(compactLayout.compactAnchorFrame.midX == compactLayout.cutoutFrame.midX)
        #expect(expandedLayout.compactAnchorFrame.midX == expandedLayout.expandedFrame.midX)
    }
}
