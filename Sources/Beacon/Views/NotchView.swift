import SwiftUI

struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if isExpanded {
                ExpandedView(viewModel: viewModel)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            CompactView(
                healthScore: viewModel.healthScore,
                issueCount: viewModel.issueCount,
                isScanning: viewModel.isScanning
            )
            .frame(height: 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onHover { hovering in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded = hovering
            }
        }
    }
}
