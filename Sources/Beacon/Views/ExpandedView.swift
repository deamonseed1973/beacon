import AppKit
import SwiftUI

struct ExpandedView: View {
    @ObservedObject var viewModel: NotchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            summaryRow
            contentCard
            actionRow
            footer
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 16)
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

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.appName.isEmpty ? "Waiting for a foreground app" : viewModel.appName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Label {
                    Text(statusHeadline)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: statusSymbol)
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(statusColor.opacity(0.92))
                .labelStyle(.titleAndIcon)
            }

            Spacer()

            statusBadge
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 10) {
            issuesButtonTile
            statTile(title: "State", value: stateValue, accent: Color.white.opacity(0.78))
        }
    }

    @ViewBuilder
    private var contentCard: some View {
        switch viewModel.expandedContentMode {
        case .preview:
            previewCard
        case .issues:
            issuesListCard
        }
    }

    private var previewCard: some View {
        Button {
            viewModel.expandedContentMode = .preview
            viewModel.previewAnnotatedScreenshotAction()
        } label: {
            Group {
                if let screenshot = viewModel.annotatedScreenshot {
                    GeometryReader { proxy in
                        let size = screenshot.size
                        let aspectRatio = size.height > 0 ? size.width / size.height : 1.6

                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.black.opacity(0.18))

                            Image(nsImage: screenshot)
                                .resizable()
                                .aspectRatio(aspectRatio, contentMode: .fit)
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipped()

                            HStack(spacing: 8) {
                                Text(screenshotCaption)
                                Spacer(minLength: 8)
                                Label("Quick Look", systemImage: "arrow.up.left.and.arrow.down.right")
                            }
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
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 164)
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
                    .frame(height: 164)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.annotatedScreenshot == nil)
        .opacity(viewModel.annotatedScreenshot == nil ? 0.92 : 1)
    }

    private var issuesListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Issue List", systemImage: "list.bullet.rectangle.portrait")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    withAnimation(.easeOut(duration: 0.18)) {
                        viewModel.expandedContentMode = .preview
                    }
                } label: {
                    Label("Preview", systemImage: "photo")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .buttonStyle(.plain)
            }

            if viewModel.issues.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No issues in the current report")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Capture a fresh report to inspect accessibility gaps for the frontmost window.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.58))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(viewModel.issues, id: \.index) { issue in
                            issueRow(issue)
                        }
                    }
                    .padding(.trailing, 2)
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: 164, alignment: .topLeading)
        .background(
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
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 8) {
            actionButton(
                title: "Capture",
                subtitle: viewModel.captureShortcut,
                systemImage: "camera.aperture",
                action: viewModel.captureAction
            )
            actionButton(
                title: "Export",
                subtitle: viewModel.exportShortcut,
                systemImage: "square.and.arrow.up",
                action: exportReport
            )
            actionButton(
                title: "Reports",
                subtitle: viewModel.reportsShortcut,
                systemImage: "folder",
                action: openReportsFolder
            )
        }
    }

    private var footer: some View {
        Text(footerText)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.58))
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: statusSymbol)
                .font(.system(size: 10, weight: .bold))
            Text(statusBadgeTitle)
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
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

    private var issuesButtonTile: some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) {
                viewModel.expandedContentMode = viewModel.expandedContentMode == .issues ? .preview : .issues
            }
        } label: {
            statTile(
                title: "Issues",
                value: issueValue,
                accent: statusColor,
                isSelected: viewModel.expandedContentMode == .issues
            )
        }
        .buttonStyle(.plain)
    }

    private func statTile(
        title: String,
        value: String,
        accent: Color,
        isSelected: Bool = false
    ) -> some View {
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
                .fill(isSelected ? accent.opacity(0.14) : Color.white.opacity(0.05))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accent.opacity(isSelected ? 0.36 : 0.18), lineWidth: 1)
        }
    }

    private func issueRow(_ issue: AccessibilityIssue) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("#\(issue.index)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.6))

                Text(issue.elementRole)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text(issue.issueType == .gap ? "Gap" : "Mismatch")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
            }

            Text(issue.visualText.isEmpty ? "Visible text detected without a matching accessibility label." : issue.visualText)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func actionButton(
        title: String,
        subtitle: String?,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.58))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.07))
            )
        }
        .buttonStyle(.plain)
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

    private var statusSymbol: String {
        if viewModel.isScanning { return "dot.radiowaves.left.and.right" }
        switch viewModel.healthScore {
        case .good:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .critical:
            return "xmark.octagon.fill"
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
            return "Beacon is analysing the frontmost app. \(viewModel.toggleShortcut) hides or shows the notch UI."
        }
        return "\(viewModel.captureShortcut) captures a fresh report. \(viewModel.toggleShortcut) hides or shows the notch UI."
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
