import AppKit
import SwiftUI

final class NotchHostingController: NSHostingController<NotchView> {
    init(viewModel: NotchViewModel) {
        super.init(rootView: NotchView(viewModel: viewModel))
    }

    @MainActor @preconcurrency required dynamic init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
    }
}
