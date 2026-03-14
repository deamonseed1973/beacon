import SwiftUI

struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel
    let onExpansionChanged: (Bool) -> Void
    @State private var isExpanded = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear

            VStack(spacing: NotchChromeMetrics.compactToExpandedSpacing) {
                CompactView(
                    layout: viewModel.layout,
                    healthScore: viewModel.healthScore,
                    issueCount: viewModel.issueCount,
                    isScanning: viewModel.isScanning
                )

                if isExpanded {
                    ExpandedView(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(
            width: viewModel.layout.windowFrame.width,
            height: viewModel.layout.windowFrame.height,
            alignment: .top
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded = hovering
            }
            onExpansionChanged(hovering)
        }
    }
}
