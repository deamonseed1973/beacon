import AppKit
import SwiftUI

struct ExpandedView: View {
    @ObservedObject var viewModel: NotchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
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
                    .truncationMode(.tail)

                Spacer()
            }

            // Issue summary
            if let report = viewModel.report {
                Text(issueSummary(report))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)

                // Annotated screenshot thumbnail
                if let screenshot = viewModel.annotatedScreenshot {
                    Image(nsImage: screenshot)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }

                // Action buttons
                HStack(spacing: 8) {
                    actionButton(
                        title: "Reports",
                        systemImage: "folder",
                        shortcut: nil,
                        action: openReportsFolder
                    )
                    actionButton(
                        title: "Capture Now",
                        systemImage: "camera.aperture",
                        shortcut: viewModel.captureShortcut,
                        action: viewModel.captureAction
                    )
                    actionButton(
                        title: "Export Report",
                        systemImage: "square.and.arrow.up",
                        shortcut: nil,
                        action: exportReport
                    )
                }
            } else if viewModel.isScanning {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                    Text("Scanning accessibility tree…")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
            } else {
                Text("Switch to an app to begin")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Text("Toggle Beacon: \(viewModel.toggleShortcut)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
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

    private func actionButton(
        title: String,
        systemImage: String,
        shortcut: String?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                if let shortcut {
                    Text(shortcut)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                        )
                }
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.14))
            )
        }
        .buttonStyle(.plain)
    }

    private func issueSummary(_ report: AuditReport) -> String {
        let count = report.issues.count
        if count == 0 {
            return "✓ No accessibility gaps found"
        }
        return "\(count) accessibility gap\(count == 1 ? "" : "s") found"
    }

    private func openReportsFolder() {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Desktop/beacon-reports")
        NSWorkspace.shared.open(dir)
    }

    private func exportReport() {
        viewModel.exportAction()
    }
}
