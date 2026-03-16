import SwiftUI

struct CompactView: View {
    let layout: NotchLayout
    let healthScore: HealthScore
    let issueCount: Int
    let isScanning: Bool
    let isExpanded: Bool
    let isHovering: Bool

    var body: some View {
        VStack(spacing: -NotchChromeMetrics.compactBridgeOverlap) {
            Capsule()
                .fill(bridgeFill)
                .frame(width: layout.bridgeWidth, height: NotchChromeMetrics.bridgeHeight)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                }
                .overlay(alignment: .bottom) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: layout.bridgeWidth - 18, height: 1)
                        .blur(radius: 0.5)
                        .offset(y: -2)
                }

            HStack(spacing: 10) {
                statusOrb

                VStack(alignment: .leading, spacing: 1) {
                    Text(titleText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .lineLimit(1)

                    Text(countLabel)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.white.opacity(isHovering || isExpanded ? 0.9 : 0.55))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(isHovering || isExpanded ? 0.12 : 0.06))
                    )
            }
            .frame(minWidth: layout.compactTrayWidth, minHeight: NotchChromeMetrics.compactHeight)
            .padding(.horizontal, 16)
            .background {
                Capsule()
                    .fill(panelFill)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    }
                    .overlay {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12),
                                        .clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                            .padding(1)
                    }
            }
            .clipShape(Capsule(style: .continuous))
            .shadow(color: .black.opacity(isExpanded ? 0.32 : 0.24), radius: 18, y: 9)
        }
        .frame(width: layout.compactSize.width, height: layout.compactSize.height, alignment: .top)
        .scaleEffect(isExpanded ? 1.0 : (isHovering ? 1.015 : 1.0), anchor: .top)
        .animation(.spring(response: 0.26, dampingFraction: 0.84), value: isExpanded)
        .animation(.easeOut(duration: 0.16), value: isHovering)
        .compositingGroup()
    }

    private var titleText: String {
        if isScanning { return "Beacon is scanning" }
        switch healthScore {
        case .good:
            return "Accessibility healthy"
        case .warning:
            return "Needs attention"
        case .critical:
            return "Critical gaps"
        }
    }

    private var countLabel: String {
        if isScanning { return "Scanning" }
        let label = issueCount == 1 ? "issue" : "issues"
        return "\(issueCount) \(label)"
    }

    private var statusOrb: some View {
        ZStack {
            Circle()
                .fill(dotColor.opacity(0.25))
                .frame(width: 24, height: 24)

            Circle()
                .fill(dotColor)
                .frame(width: 12, height: 12)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                }
                .overlay {
                    if isScanning {
                        Circle()
                            .stroke(dotColor.opacity(0.45), lineWidth: 1.5)
                            .scaleEffect(1.8)
                            .opacity(0)
                            .animation(
                                .easeOut(duration: 1.15).repeatForever(autoreverses: false),
                                value: isScanning
                            )
                    }
                }
        }
    }

    private var panelFill: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.11, green: 0.12, blue: 0.14),
                Color(red: 0.03, green: 0.04, blue: 0.06)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var bridgeFill: some ShapeStyle {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.09, blue: 0.11),
                Color(red: 0.02, green: 0.03, blue: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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
