import AppKit
import CodexStatusRadarCore
import SwiftUI

@MainActor
final class NotchStatusWindowController {
    private let window: NotchPanel
    private let store = DynamicIslandSurfaceStore()

    init(isDemoMode: Bool = false) {
        window = NotchPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: NotchLayoutMetrics.windowSize.width,
                height: NotchLayoutMetrics.windowSize.height
            ),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.backgroundColor = .clear
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.isOpaque = false
        window.isReleasedWhenClosed = false
        window.level = isDemoMode ? .screenSaver : .statusBar
        window.contentView = NSHostingView(rootView: DynamicIslandSurfaceView(store: store))
    }

    func showStatus(_ phase: CodexPhase) {
        store.showStatus(phase)
        syncInteractivity()
        show()
    }

    func showApproval(
        _ viewModel: ApprovalRequestViewModel,
        onSelect: @escaping (ApprovalAction) -> Void
    ) {
        store.showApproval(viewModel, onSelect: onSelect)
        syncInteractivity()
        show()
    }

    private func syncInteractivity() {
        window.ignoresMouseEvents = !store.isInteractive
        window.acceptsMouseMovedEvents = store.isInteractive
    }

    private func show() {
        guard let screen = targetScreen() else {
            return
        }

        let screenFrame = screen.frame
        window.setContentSize(NotchLayoutMetrics.windowSize)
        window.setFrameOrigin(
            NSPoint(
                x: screenFrame.midX - window.frame.width / 2,
                y: screenFrame.maxY - window.frame.height
            )
        )
        window.orderFrontRegardless()
    }

    private func targetScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            NSMouseInRect(mouseLocation, screen.frame, false)
        } ?? NSScreen.main ?? NSScreen.screens.first
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
