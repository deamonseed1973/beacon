import CoreGraphics
import Testing
@testable import Beacon

struct ScreenAnnotatorTests {
    @Test("Translates issue frames into captured-window coordinates")
    func translatesIssueFrameIntoWindowCoordinates() {
        let annotator = ScreenAnnotator()
        let rect = annotator.annotationRect(
            for: CGRect(x: 140, y: 260, width: 80, height: 40),
            capturedFrame: CGRect(x: 100, y: 200, width: 400, height: 300),
            imageSize: CGSize(width: 800, height: 600)
        )

        #expect(rect.origin.x == 80)
        #expect(rect.origin.y == 400)
        #expect(rect.width == 160)
        #expect(rect.height == 80)
    }
}
