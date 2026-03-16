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
    func annotate(screenshot: CGImage, issues: [AccessibilityIssue], capturedFrame: CGRect) -> NSImage {
        let size = CGSize(width: screenshot.width, height: screenshot.height)
        let image = NSImage(size: size)

        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return NSImage(cgImage: screenshot, size: size)
        }

        context.draw(screenshot, in: CGRect(origin: .zero, size: size))

        var placedLabels: [CGRect] = []
        let imageBounds = CGRect(origin: .zero, size: size)

        for issue in issues {
            let color = issue.issueType == .gap ? style.gapColor : style.mismatchColor
            let rect = annotationRect(
                for: issue.frame.cgRect,
                capturedFrame: capturedFrame,
                imageSize: size
            )
            guard rect.intersects(imageBounds) else { continue }

            context.setStrokeColor(color.cgColor)
            context.setLineWidth(style.borderWidth)
            context.stroke(rect)

            let labelText = "\(issue.elementRole) #\(issue.index)"
            let labelRect = bestLabelPosition(
                for: rect,
                text: labelText,
                imageSize: size,
                existing: placedLabels
            )

            context.setFillColor(style.labelBackground.cgColor)
            context.fill(labelRect)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: style.labelFont,
                .foregroundColor: style.labelTextColor,
            ]
            (labelText as NSString).draw(in: labelRect.insetBy(dx: 3, dy: 1), withAttributes: attributes)

            placedLabels.append(labelRect)
        }

        image.unlockFocus()
        return image
    }

    func annotationRect(for issueFrame: CGRect, capturedFrame: CGRect, imageSize: CGSize) -> CGRect {
        let scaleX = imageSize.width / max(capturedFrame.width, 1)
        let scaleY = imageSize.height / max(capturedFrame.height, 1)

        let localX = (issueFrame.minX - capturedFrame.minX) * scaleX
        let localY = (capturedFrame.maxY - issueFrame.maxY) * scaleY

        return CGRect(
            x: localX,
            y: localY,
            width: issueFrame.width * scaleX,
            height: issueFrame.height * scaleY
        )
    }

    private func bestLabelPosition(
        for elementRect: CGRect,
        text: String,
        imageSize: CGSize,
        existing: [CGRect]
    ) -> CGRect {
        let attributes: [NSAttributedString.Key: Any] = [.font: style.labelFont]
        let textSize = (text as NSString).size(withAttributes: attributes)
        let labelSize = CGSize(width: textSize.width + 6, height: textSize.height + 2)

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

        for candidate in candidates {
            if imageBounds.contains(candidate) &&
               !existing.contains(where: { $0.intersects(candidate) }) {
                return candidate
            }
        }

        var fallback = candidates[0]
        fallback.origin.x = max(0, min(fallback.origin.x, imageSize.width - fallback.width))
        fallback.origin.y = max(0, min(fallback.origin.y, imageSize.height - fallback.height))
        return fallback
    }
}
