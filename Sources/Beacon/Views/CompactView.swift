import SwiftUI

struct CompactView: View {
    let layout: NotchLayout
    let healthScore: HealthScore
    let issueCount: Int
    let isScanning: Bool

    var body: some View {
        VStack(spacing: -NotchChromeMetrics.compactBridgeOverlap) {
            Capsule()
                .fill(panelFill)
                .frame(width: layout.bridgeWidth, height: NotchChromeMetrics.bridgeHeight)
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                }

            HStack(spacing: 10) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 14, height: 14)
                    .overlay {
                        if isScanning {
                            Circle()
                                .stroke(Color.white.opacity(0.55), lineWidth: 1.5)
                                .scaleEffect(1.45)
                                .opacity(0)
                                .animation(
                                    .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                                    value: isScanning
                                )
                        }
                    }

                Text(countLabel)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
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
            }
            .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
        }
        .frame(width: layout.compactSize.width, height: layout.compactSize.height, alignment: .top)
    }

    private var countLabel: String {
        if isScanning { return "…" }
        return "\(issueCount)"
    }

    private var panelFill: some ShapeStyle {
        LinearGradient(
            colors: [
                Color.black.opacity(0.95),
                Color.black.opacity(0.88)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var dotColor: Color {
        if isScanning { return .gray.opacity(0.9) }
        switch healthScore {
        case .good: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }
}
