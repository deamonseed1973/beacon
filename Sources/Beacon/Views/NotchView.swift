import SwiftUI

struct NotchView: View {
    @ObservedObject var viewModel: NotchViewModel
    let onExpansionChanged: (Bool) -> Void
    @State private var isHoveringCompact = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear

            compactButton
                .offset(
                    x: viewModel.layout.compactOriginInWindow.x,
                    y: viewModel.layout.compactOriginInWindow.y
                )

            expandedPanel
        }
        .frame(
            width: viewModel.layout.windowFrame.width,
            height: viewModel.layout.windowFrame.height,
            alignment: .top
        )
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: viewModel.isExpanded)
    }

    private var compactButton: some View {
        Button {
            toggleExpansion()
        } label: {
            CompactView(
                layout: viewModel.layout,
                healthScore: viewModel.healthScore,
                issueCount: viewModel.issueCount,
                isScanning: viewModel.isScanning,
                isExpanded: viewModel.isExpanded,
                isHovering: isHoveringCompact
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.18)) {
                isHoveringCompact = hovering
            }
        }
    }

    @ViewBuilder
    private var expandedPanel: some View {
        if viewModel.isExpanded {
            ExpandedView(viewModel: viewModel)
                .offset(
                    x: viewModel.layout.expandedOriginInWindow.x,
                    y: viewModel.layout.expandedOriginInWindow.y
                )
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .top)),
                        removal: .opacity
                    )
                )
        }
    }

    private func toggleExpansion() {
        let nextState = !viewModel.isExpanded
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            viewModel.isExpanded = nextState
        }
        onExpansionChanged(nextState)
    }
}
