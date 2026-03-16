import AppKit
import Quartz

@MainActor
final class QuickLookPreviewController: NSObject, @preconcurrency QLPreviewPanelDataSource {
    private var previewItemURL: NSURL?

    func preview(image: NSImage, suggestedFileName: String) throws {
        let sanitizedName = suggestedFileName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("beacon-preview-\(sanitizedName)")
            .appendingPathExtension("png")

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw PreviewError.encodingFailed
        }

        try pngData.write(to: url, options: .atomic)
        previewItemURL = url as NSURL

        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewItemURL == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        previewItemURL
    }
}

enum PreviewError: Error {
    case encodingFailed
}
