import SwiftUI

struct CompactView: View {
    let layout: NotchLayout
    let healthScore: HealthScore
    let issueCount: Int
    let isScanning: Bool
    let isExpanded: Bool
    let isHovering: Bool

    var body: some View {
        HStack(spacing: 12) {
            statusOrb

            VStack(alignment: .leading, spacing: 2) {
                Text(compactStatusText)
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .lineLimit(1)

                Text(compactPrimaryText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 10)

            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.white.opacity(isHovering || isExpanded ? 0.92 : 0.62))
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(Color.white.opacity(isHovering || isExpanded ? 0.12 : 0.08))
                )
        }
        .padding(.horizontal, 16)
        .frame(width: layout.compactSize.width, height: layout.compactSize.height)
        .background(capsuleBackground)
        .clipShape(Capsule(style: .continuous))
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(isExpanded ? 0.3 : 0.22), radius: 18, y: 10)
        .scaleEffect(isExpanded ? 1.0 : (isHovering ? 1.004 : 1.0))
        .animation(.easeOut(duration: 0.16), value: isHovering)
        .compositingGroup()
    }

    private var capsuleBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.14, green: 0.15, blue: 0.18),
                Color(red: 0.03, green: 0.04, blue: 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    .clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .clipShape(Capsule(style: .continuous))
            .padding(1)
        }
    }

    private var statusOrb: some View {
        ZStack {
            Circle()
                .fill(dotColor.opacity(0.22))
                .frame(width: 30, height: 30)

            Circle()
                .fill(dotColor)
                .frame(width: 16, height: 16)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                }
                .overlay {
                    if isScanning {
                        Circle()
                            .stroke(dotColor.opacity(0.45), lineWidth: 1.5)
                            .scaleEffect(1.65)
                            .opacity(0)
                            .animation(
                                .easeOut(duration: 1.15).repeatForever(autoreverses: false),
                                value: isScanning
                            )
                    }
                }
        }
    }

    private var compactStatusText: String {
        if isScanning { return "Scanning" }
        switch healthScore {
        case .good:
            return "All clear"
        case .warning:
            return "Needs attention"
        case .critical:
            return "Critical gaps"
        }
    }

    private var compactPrimaryText: String {
        if isScanning { return "Live scan" }
        let label = issueCount == 1 ? "issue" : "issues"
        return "\(issueCount) \(label)"
    }

    private var dotColor: Color {
        if isScanning { return Color(red: 0.73, green: 0.76, blue: 0.82) }
        switch healthScore {
        case .good:
            return Color(red: 0.32, green: 0.86, blue: 0.58)
        case .warning:
            return Color(red: 0.95, green: 0.76, blue: 0.24)
        case .critical:
            return Color(red: 0.97, green: 0.42, blue: 0.34)
        }
    }
}
