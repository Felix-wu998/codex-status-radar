import AppKit
import CodexStatusRadarCore
import SwiftUI

@MainActor
final class NotchStatusWindowController {
    private let window: NotchPanel

    init(isDemoMode: Bool = false) {
        window = NotchPanel(
            contentRect: NSRect(x: 0, y: 0, width: 72, height: 30),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.isOpaque = false
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.level = isDemoMode ? .screenSaver : .statusBar
    }

    func showStatus(_ phase: CodexPhase) {
        let statusView = NotchStatusView(phase: phase)
            .frame(width: 92, height: 34)
            .background(.black.opacity(0.001))
        window.contentView = NSHostingView(rootView: statusView)
        window.setContentSize(NSSize(width: 92, height: 34))
        show()
    }

    func showApproval(
        _ viewModel: ApprovalRequestViewModel,
        onSelect: @escaping (ApprovalAction) -> Void
    ) {
        let approvalView = ApprovalPopoverView(
            viewModel: viewModel,
            onSelect: onSelect
        )
        window.contentView = NSHostingView(rootView: approvalView)
        window.setContentSize(NSSize(width: 380, height: 150))
        show()
    }

    private func show() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return
        }

        let screenFrame = screen.visibleFrame
        window.setFrameOrigin(
            NSPoint(
                x: screenFrame.midX - window.frame.width / 2,
                y: screenFrame.maxY - window.frame.height - 8
            )
        )
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}

private final class NotchPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }
}
