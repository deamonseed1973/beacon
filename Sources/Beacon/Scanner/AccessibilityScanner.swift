import ApplicationServices
import AppKit
import Vision

struct ScanResult {
    let report: AuditReport
    let windowFrame: CGRect?
}

/// Orchestrates the full scan pipeline:
/// AX tree walk → fast TextDetector pre-pass → Vision OCR for positive hits.
actor AccessibilityScanner {
    private let textDetector = TextDetector()

    func scan(app: NSRunningApplication, windowFrameHint: CGRect? = nil) async -> ScanResult {
        let appName = app.localizedName ?? "Unknown"
        let bundleID = app.bundleIdentifier ?? ""
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        let root = AXElement(underlying: appElement)
        let focusedWindow = root.focusedWindow
        let scopedWindowFrame = focusedWindow?.frame ?? windowFrameHint
        let scanRoot = focusedWindow ?? root

        let walker = AXTreeWalker()
        let elements = walker.collectElements(root: scanRoot)

        var issues: [AccessibilityIssue] = []
        var issueIndex = 0

        for element in elements {
            guard let frame = element.frame,
                  frame.width > 20,
                  frame.height > 20,
                  Self.shouldInspectElement(frame: frame, within: scopedWindowFrame) else {
                continue
            }

            if element.hasText { continue }
            guard let role = element.role else { continue }
            guard let cgImage = ElementCapture.capture(frame: frame) else { continue }

            let detection = textDetector.analyze(cgImage)
            guard detection.hasText else { continue }

            let visualText = await recognizeText(in: cgImage)
            guard !visualText.isEmpty else { continue }

            issues.append(AccessibilityIssue(
                index: issueIndex,
                elementRole: role,
                axText: element.textContent,
                visualText: visualText,
                frame: CodableRect(frame),
                issueType: element.textContent.isEmpty ? .gap : .mismatch
            ))
            issueIndex += 1
        }

        return ScanResult(
            report: AuditReport(
                appName: appName,
                bundleID: bundleID,
                timestamp: Date(),
                totalElements: elements.count,
                issues: issues
            ),
            windowFrame: scopedWindowFrame
        )
    }

    static func shouldInspectElement(frame: CGRect, within windowFrame: CGRect?) -> Bool {
        guard let windowFrame else { return true }
        guard windowFrame.intersects(frame) else { return false }
        return windowFrame.contains(CGPoint(x: frame.midX, y: frame.midY))
    }

    private func recognizeText(in image: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: " ")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .fast
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
}
