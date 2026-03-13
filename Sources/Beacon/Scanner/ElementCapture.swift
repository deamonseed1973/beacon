import CoreGraphics
import AppKit

/// Captures a CGImage for a given screen rect (the on-screen bounds of an AX element).
enum ElementCapture {
    /// Capture the given rect from the main display.
    /// The frame is in Cocoa coordinates (origin bottom-left); this converts to CG coordinates.
    static func capture(frame: CGRect) -> CGImage? {
        guard let screen = NSScreen.main else { return nil }

        // Convert from Cocoa (bottom-left origin) to CG (top-left origin)
        let screenHeight = screen.frame.height
        let cgRect = CGRect(
            x: frame.origin.x,
            y: screenHeight - frame.origin.y - frame.height,
            width: frame.width,
            height: frame.height
        )

        return CGWindowListCreateImage(
            cgRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        )
    }

    /// Capture the full screen.
    static func captureFullScreen() -> CGImage? {
        guard let screen = NSScreen.main else { return nil }
        return CGWindowListCreateImage(
            screen.frame,
            .optionOnScreenOnly,
            kCGNullWindowID,
            [.bestResolution]
        )
    }
}
