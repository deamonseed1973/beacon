import CoreGraphics
import Testing
@testable import Beacon

struct ElementCaptureTests {
    @Test("Prefers the window that overlaps the requested frame")
    func resolvesPreferredWindow() {
        let infoList: [[String: Any]] = [
            [
                String(kCGWindowOwnerPID): pid_t(42),
                String(kCGWindowNumber): CGWindowID(1001),
                String(kCGWindowLayer): 0,
                String(kCGWindowAlpha): 1.0,
                String(kCGWindowBounds): CGRect(x: 0, y: 0, width: 400, height: 300).dictionaryRepresentation
            ],
            [
                String(kCGWindowOwnerPID): pid_t(42),
                String(kCGWindowNumber): CGWindowID(1002),
                String(kCGWindowLayer): 0,
                String(kCGWindowAlpha): 1.0,
                String(kCGWindowBounds): CGRect(x: 600, y: 200, width: 500, height: 400).dictionaryRepresentation
            ]
        ]

        let descriptor = ElementCapture.resolveFrontmostWindow(
            in: infoList,
            pid: 42,
            preferredFrame: CGRect(x: 650, y: 250, width: 200, height: 100)
        )

        #expect(descriptor?.windowID == 1002)
    }
}
