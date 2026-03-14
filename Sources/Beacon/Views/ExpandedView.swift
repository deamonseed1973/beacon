import SwiftUI

struct ExpandedView: View {
    @ObservedObject var viewModel: NotchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // App info row
            HStack(spacing: 10) {
                if let icon = viewModel.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 34, height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Text(viewModel.appName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()
            }

            // Issue summary
            if let report = viewModel.report {
                Text(issueSummary(report))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))

                // Annotated screenshot thumbnail
                if let screenshot = viewModel.annotatedScreenshot {
                    Image(nsImage: screenshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }

                // Export button
                Button(action: exportReport) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Export Report")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                    )
                }
                .buttonStyle(.plain)
            } else if viewModel.isScanning {
                Text("Scanning...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(16)
        .frame(width: viewModel.layout.expandedSize.width, height: viewModel.layout.expandedSize.height, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.96),
                            Color.black.opacity(0.88)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                }
        )
        .shadow(color: .black.opacity(0.32), radius: 22, y: 10)
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
