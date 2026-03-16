import CoreGraphics
import AppKit

struct WindowDescriptor: Equatable {
    let windowID: CGWindowID
    let frame: CGRect
}

struct WindowCapture {
    let frame: CGRect
    let image: CGImage
}

/// Captures CGImages for element rects and frontmost application windows.
enum ElementCapture {
    /// Capture the given rect from the main display.
    /// The frame is in Cocoa coordinates (origin bottom-left); this converts to CG coordinates.
    static func capture(frame: CGRect) -> CGImage? {
        guard let screen = NSScreen.main else { return nil }

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

    static func resolveFrontmostWindow(
        for app: NSRunningApplication,
        preferredFrame: CGRect? = nil
    ) -> WindowDescriptor? {
        guard let infoList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }

        return resolveFrontmostWindow(
            in: infoList,
            pid: app.processIdentifier,
            preferredFrame: preferredFrame
        )
    }

    static func captureWindow(_ descriptor: WindowDescriptor) -> WindowCapture? {
        guard let image = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            descriptor.windowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            return nil
        }

        return WindowCapture(frame: descriptor.frame, image: image)
    }

    static func captureFrontmostWindow(
        for app: NSRunningApplication,
        preferredFrame: CGRect? = nil
    ) -> WindowCapture? {
        guard let descriptor = resolveFrontmostWindow(for: app, preferredFrame: preferredFrame) else {
            return nil
        }
        return captureWindow(descriptor)
    }

    static func resolveFrontmostWindow(
        in windowInfoList: [[String: Any]],
        pid: pid_t,
        preferredFrame: CGRect? = nil
    ) -> WindowDescriptor? {
        let candidates = windowInfoList.compactMap { info -> WindowDescriptor? in
            guard let ownerPID = numericValue(info[String(kCGWindowOwnerPID)]).map(pid_t.init),
                  ownerPID == pid,
                  let windowID = numericValue(info[String(kCGWindowNumber)]).map(CGWindowID.init),
                  let layer = numericValue(info[String(kCGWindowLayer)]),
                  layer == 0,
                  let alpha = doubleValue(info[String(kCGWindowAlpha)]),
                  alpha > 0.01,
                  let boundsDictionary = info[String(kCGWindowBounds)] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary),
                  bounds.width > 40,
                  bounds.height > 40 else {
                return nil
            }

            return WindowDescriptor(windowID: windowID, frame: bounds)
        }

        guard !candidates.isEmpty else { return nil }
        guard let preferredFrame else { return candidates.first }

        return candidates.max { lhs, rhs in
            windowMatchScore(for: lhs.frame, preferredFrame: preferredFrame)
                < windowMatchScore(for: rhs.frame, preferredFrame: preferredFrame)
        } ?? candidates.first
    }

    static func windowMatchScore(for frame: CGRect, preferredFrame: CGRect) -> CGFloat {
        let intersection = frame.intersection(preferredFrame)
        let intersectionArea = intersection.isNull ? 0 : intersection.width * intersection.height
        let containsPreferredCenter = frame.contains(CGPoint(x: preferredFrame.midX, y: preferredFrame.midY))
        return intersectionArea + (containsPreferredCenter ? 1_000_000 : 0)
    }

    private static func numericValue(_ value: Any?) -> Int? {
        if let number = value as? NSNumber {
            return number.intValue
        }
        return value as? Int
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        return value as? Double
    }
}
