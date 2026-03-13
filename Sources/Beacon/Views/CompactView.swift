import SwiftUI

struct CompactView: View {
    let healthScore: HealthScore
    let issueCount: Int
    let isScanning: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 10, height: 10)
                .overlay {
                    if isScanning {
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            .scaleEffect(1.5)
                            .opacity(0)
                            .animation(
                                .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                                value: isScanning
                            )
                    }
                }

            if issueCount > 0 {
                Text("\(issueCount)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
        )
    }

    private var dotColor: Color {
        if isScanning { return .gray }
        switch healthScore {
        case .good: return .green
        case .warning: return .yellow
        case .critical: return .red
        }
    }
}
