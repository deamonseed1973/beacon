import ApplicationServices
import AppKit
import Vision

/// Orchestrates the full scan pipeline:
/// AX tree walk → fast TextDetector pre-pass → Vision OCR for positive hits.
actor AccessibilityScanner {
    private let textDetector = TextDetector()

    func scan(app: NSRunningApplication) async -> AuditReport {
        let appName = app.localizedName ?? "Unknown"
        let bundleID = app.bundleIdentifier ?? ""
        let pid = app.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)
        let root = AXElement(underlying: appElement)

        let walker = AXTreeWalker()
        let elements = walker.collectElements(root: root)

        var issues: [AccessibilityIssue] = []
        var issueIndex = 0

        for element in elements {
            guard let frame = element.frame,
                  frame.width > 20, frame.height > 20 else {
                continue
            }

            // Skip elements that already have AX text
            if element.hasText { continue }

            guard let role = element.role else { continue }

            // Capture CGImage of the element's on-screen bounds
            guard let cgImage = ElementCapture.capture(frame: frame) else { continue }

            // Fast Sobel-based text detection first
            let detection = textDetector.analyze(cgImage)
            guard detection.hasText else { continue }

            // Confirmed edge presence — run Vision OCR
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

        return AuditReport(
            appName: appName,
            bundleID: bundleID,
            timestamp: Date(),
            totalElements: elements.count,
            issues: issues
        )
    }

    private func recognizeText(in image: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
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
