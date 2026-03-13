import AppKit
import CoreGraphics

/// Draws labeled bounding boxes on a screenshot for accessibility issues.
/// Inspired by Peekaboo's SmartLabelPlacer — uses simple quadrant-preference logic
/// to place labels without overlapping each other.
final class ScreenAnnotator {
    struct AnnotationStyle {
        var gapColor: NSColor = .systemRed
        var mismatchColor: NSColor = .systemOrange
        var labelFont: NSFont = .systemFont(ofSize: 10, weight: .semibold)
        var labelBackground: NSColor = .black.withAlphaComponent(0.75)
        var labelTextColor: NSColor = .white
        var borderWidth: CGFloat = 2
    }

    private let style: AnnotationStyle

    init(style: AnnotationStyle = AnnotationStyle()) {
        self.style = style
    }

    /// Annotate a screenshot with issue bounding boxes and labels.
    func annotate(screenshot: CGImage, issues: [AccessibilityIssue]) -> NSImage {
        let size = NSSize(width: screenshot.width, height: screenshot.height)
        let image = NSImage(size: size)

        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return NSImage(cgImage: screenshot, size: size)
        }

        // Draw original screenshot
        context.draw(screenshot, in: CGRect(origin: .zero, size: size))

        var placedLabels: [CGRect] = []

        for issue in issues {
            let color = issue.issueType == .gap ? style.gapColor : style.mismatchColor

            // Convert frame: flip Y since CGContext has bottom-left origin matching
            let issueFrame = issue.frame.cgRect
            let rect = CGRect(
                x: issueFrame.origin.x,
                y: CGFloat(screenshot.height) - issueFrame.origin.y - issueFrame.height,
                width: issueFrame.width,
                height: issueFrame.height
            )

            // Draw bounding box
            context.setStrokeColor(color.cgColor)
            context.setLineWidth(style.borderWidth)
            context.stroke(rect)

            // Place label
            let labelText = "\(issue.elementRole) #\(issue.index)"
            let labelRect = bestLabelPosition(
                for: rect,
                text: labelText,
                imageSize: size,
                existing: placedLabels
            )

            // Draw label background
            context.setFillColor(style.labelBackground.cgColor)
            context.fill(labelRect)

            // Draw label text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: style.labelFont,
                .foregroundColor: style.labelTextColor,
            ]
            let nsString = labelText as NSString
            let textRect = labelRect.insetBy(dx: 3, dy: 1)
            nsString.draw(in: textRect, withAttributes: attributes)

            placedLabels.append(labelRect)
        }

        image.unlockFocus()
        return image
    }

    /// Find a non-overlapping position for a label near the given rect.
    /// Tries top-left, top-right, bottom-left, bottom-right in order.
    private func bestLabelPosition(
        for elementRect: CGRect,
        text: String,
        imageSize: NSSize,
        existing: [CGRect]
    ) -> CGRect {
        let attributes: [NSAttributedString.Key: Any] = [.font: style.labelFont]
        let textSize = (text as NSString).size(withAttributes: attributes)
        let labelSize = CGSize(width: textSize.width + 6, height: textSize.height + 2)

        // Candidate positions: above-left, above-right, below-left, below-right
        let candidates: [CGRect] = [
            CGRect(x: elementRect.minX, y: elementRect.maxY + 2,
                   width: labelSize.width, height: labelSize.height),
            CGRect(x: elementRect.maxX - labelSize.width, y: elementRect.maxY + 2,
                   width: labelSize.width, height: labelSize.height),
            CGRect(x: elementRect.minX, y: elementRect.minY - labelSize.height - 2,
                   width: labelSize.width, height: labelSize.height),
            CGRect(x: elementRect.maxX - labelSize.width, y: elementRect.minY - labelSize.height - 2,
                   width: labelSize.width, height: labelSize.height),
        ]

        let imageBounds = CGRect(origin: .zero, size: imageSize)

        // Pick first candidate that doesn't overlap existing labels and is within bounds
        for candidate in candidates {
            if imageBounds.contains(candidate) &&
               !existing.contains(where: { $0.intersects(candidate) }) {
                return candidate
            }
        }

        // Fallback: first candidate, clamped to image bounds
        var fallback = candidates[0]
        fallback.origin.x = max(0, min(fallback.origin.x, imageSize.width - fallback.width))
        fallback.origin.y = max(0, min(fallback.origin.y, imageSize.height - fallback.height))
        return fallback
    }
}
