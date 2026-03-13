import AppKit
import Foundation

/// Saves audit reports as JSON + annotated PNG to ~/Desktop/beacon-reports/.
final class ReportExporter {
    private let outputDir: URL

    init() {
        let desktop = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop")
            .appendingPathComponent("beacon-reports")
        self.outputDir = desktop
    }

    func export(report: AuditReport, annotatedImage: NSImage?) throws {
        // Create output directory
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: report.timestamp)
        let safeName = report.appName.replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
        let baseName = "\(safeName)-\(timestamp)"

        // Save JSON report
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(report)
        let jsonURL = outputDir.appendingPathComponent("\(baseName).json")
        try jsonData.write(to: jsonURL)

        // Save annotated PNG if available
        if let image = annotatedImage,
           let tiffData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            let pngURL = outputDir.appendingPathComponent("\(baseName).png")
            try pngData.write(to: pngURL)
        }

        NSLog("Beacon: Report exported to \(outputDir.path)/\(baseName)")
    }
}
