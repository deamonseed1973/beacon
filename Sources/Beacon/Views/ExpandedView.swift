import AppKit
import SwiftUI

struct ExpandedView: View {
    @ObservedObject var viewModel: NotchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // App info row
            HStack(spacing: 10) {
                if let icon = viewModel.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 28, height: 28)
                        .cornerRadius(6)
                }

                Text(viewModel.appName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()
            }

            // Issue summary
            if let report = viewModel.report {
                Text(issueSummary(report))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                // Annotated screenshot thumbnail
                if let screenshot = viewModel.annotatedScreenshot {
                    Image(nsImage: screenshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 80)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }

                // Action buttons — full width, never truncated
                HStack(spacing: 8) {
                    Button(action: openReportsFolder) {
                        HStack(spacing: 5) {
                            Image(systemName: "folder")
                                .font(.system(size: 11))
                            Text("Reports")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    Button(action: exportReport) {
                        HStack(spacing: 5) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11))
                            Text("Export Report")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.18)))
                    }
                    .buttonStyle(.plain)
                }

            } else if viewModel.isScanning {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                    Text("Scanning accessibility tree…")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            } else {
                Text("Switch to an app to begin")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 6)
    }

    private func issueSummary(_ report: AuditReport) -> String {
        let count = report.issues.count
        if count == 0 { return "✓ No accessibility gaps found" }
        return "\(count) accessibility gap\(count == 1 ? "" : "s") found"
    }

    private func openReportsFolder() {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop/beacon-reports")
        NSWorkspace.shared.open(dir)
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
