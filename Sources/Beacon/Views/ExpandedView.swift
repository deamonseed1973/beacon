import AppKit
import SwiftUI

struct ExpandedView: View {
    @ObservedObject var viewModel: NotchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summaryRow
            screenshotCard
            actionRow
            footer
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .frame(
            width: viewModel.layout.expandedSize.width,
            height: viewModel.layout.expandedSize.height,
            alignment: .topLeading
        )
        .background(panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.28), radius: 24, y: 16)
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let icon = viewModel.appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 38, height: 38)
                    .overlay {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.appName.isEmpty ? "Waiting for a foreground app" : viewModel.appName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(statusHeadline)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(statusColor.opacity(0.9))
                    .lineLimit(1)
            }

            Spacer()

            statusBadge
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            statTile(title: "Issues", value: issueValue, accent: statusColor)
            statTile(title: "State", value: stateValue, accent: Color.white.opacity(0.78))
        }
    }

    @ViewBuilder
    private var screenshotCard: some View {
        Group {
            if let screenshot = viewModel.annotatedScreenshot {
                Image(nsImage: screenshot)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 98)
                    .clipped()
                    .overlay(alignment: .bottomLeading) {
                        Text(screenshotCaption)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.82))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.black.opacity(0.48))
                            )
                            .padding(10)
                    }
            } else {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: viewModel.isScanning ? "waveform.path.ecg" : "photo.on.rectangle.angled")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.7))
                        Text(emptyScreenshotTitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white)
                        Text(emptyScreenshotMessage)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 98)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            actionButton(
                title: "Capture",
                systemImage: "camera.aperture",
                action: viewModel.captureAction
            )
            actionButton(
                title: "Export",
                systemImage: "square.and.arrow.up",
                action: exportReport
            )
            actionButton(
                title: "Reports",
                systemImage: "folder",
                action: openReportsFolder
            )
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Text(footerText)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.58))
                .lineLimit(2)

            Spacer(minLength: 8)

            shortcutBadge(viewModel.captureShortcut)
            shortcutBadge(viewModel.toggleShortcut)
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusBadgeTitle)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(statusColor.opacity(0.18))
        )
        .overlay {
            Capsule(style: .continuous)
                .stroke(statusColor.opacity(0.28), lineWidth: 1)
        }
    }

    private func statTile(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.7)
                .foregroundStyle(Color.white.opacity(0.46))

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(0.18), lineWidth: 1)
        }
    }

    private func actionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
        }
        .buttonStyle(.plain)
    }

    private func shortcutBadge(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.75))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.13, blue: 0.15),
                        Color(red: 0.04, green: 0.05, blue: 0.07)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(1)
            }
    }

    private var statusHeadline: String {
        if viewModel.isScanning { return "Fresh scan in progress" }
        if let report = viewModel.report {
            return issueSummary(report)
        }
        return "Beacon is ready to inspect the active app"
    }

    private var issueValue: String {
        if viewModel.isScanning { return "Updating" }
        let count = viewModel.issueCount
        return "\(count) \(count == 1 ? "gap" : "gaps")"
    }

    private var stateValue: String {
        if viewModel.isScanning { return "Scanning" }
        switch viewModel.healthScore {
        case .good:
            return "Healthy"
        case .warning:
            return "Warning"
        case .critical:
            return "Critical"
        }
    }

    private var statusBadgeTitle: String {
        if viewModel.isScanning { return "Scanning" }
        switch viewModel.healthScore {
        case .good:
            return "Healthy"
        case .warning:
            return "Warning"
        case .critical:
            return "Critical"
        }
    }

    private var statusColor: Color {
        if viewModel.isScanning {
            return Color(red: 0.73, green: 0.76, blue: 0.82)
        }
        switch viewModel.healthScore {
        case .good:
            return Color(red: 0.32, green: 0.86, blue: 0.58)
        case .warning:
            return Color(red: 0.95, green: 0.76, blue: 0.24)
        case .critical:
            return Color(red: 0.97, green: 0.42, blue: 0.34)
        }
    }

    private var footerText: String {
        if viewModel.isScanning {
            return "Beacon is analysing the frontmost app."
        }
        return "Capture to refresh now, or export the current accessibility report."
    }

    private var screenshotCaption: String {
        if viewModel.issueCount == 0 {
            return "No visible gaps detected"
        }
        return "\(viewModel.issueCount) highlighted \(viewModel.issueCount == 1 ? "issue" : "issues")"
    }

    private var emptyScreenshotTitle: String {
        if viewModel.isScanning {
            return "Building a fresh snapshot"
        }
        return "No annotated preview yet"
    }

    private var emptyScreenshotMessage: String {
        if viewModel.isScanning {
            return "The panel stays open while Beacon updates the screenshot."
        }
        return "Run a capture or switch apps to generate a marked screenshot preview."
    }

    private func issueSummary(_ report: AuditReport) -> String {
        let count = report.issues.count
        if count == 0 {
            return "No accessibility gaps found"
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
