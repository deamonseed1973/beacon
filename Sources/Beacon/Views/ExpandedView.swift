import SwiftUI

struct ExpandedView: View {
    @ObservedObject var viewModel: NotchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // App info row
            HStack(spacing: 8) {
                if let icon = viewModel.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .cornerRadius(4)
                }

                Text(viewModel.appName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()
            }

            // Issue summary
            if let report = viewModel.report {
                Text(issueSummary(report))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))

                // Annotated screenshot thumbnail
                if let screenshot = viewModel.annotatedScreenshot {
                    Image(nsImage: screenshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 60)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }

                // Export button
                Button(action: exportReport) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 10))
                        Text("Export Report")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
            } else if viewModel.isScanning {
                Text("Scanning...")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
        )
        .padding(.horizontal, 4)
    }

    private func issueSummary(_ report: AuditReport) -> String {
        let count = report.issues.count
        if count == 0 {
            return "No accessibility gaps found"
        }
        return "\(count) accessibility gap\(count == 1 ? "" : "s") found"
    }

    private func exportReport() {
        guard let report = viewModel.report else { return }
        let annotatedImage = viewModel.annotatedScreenshot
        let exporter = ReportExporter()
        do {
            try exporter.export(report: report, annotatedImage: annotatedImage)
        } catch {
            NSLog("Beacon: Export failed: \(error)")
        }
    }
}
