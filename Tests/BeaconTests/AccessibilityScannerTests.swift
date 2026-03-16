import CoreGraphics
import Testing
@testable import Beacon

struct AccessibilityScannerTests {
    @Test("Excludes elements outside the scoped window")
    func filtersElementsOutsideWindow() {
        let windowFrame = CGRect(x: 100, y: 100, width: 300, height: 200)

        #expect(
            AccessibilityScanner.shouldInspectElement(
                frame: CGRect(x: 150, y: 140, width: 40, height: 30),
                within: windowFrame
            )
        )
        #expect(
            !AccessibilityScanner.shouldInspectElement(
                frame: CGRect(x: 450, y: 140, width: 40, height: 30),
                within: windowFrame
            )
        )
    }
}
