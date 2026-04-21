import AppKit

@MainActor
final class MenuBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let onShowStatus: () -> Void
    private let onShowApproval: () -> Void

    init(
        onShowStatus: @escaping () -> Void,
        onShowApproval: @escaping () -> Void
    ) {
        self.onShowStatus = onShowStatus
        self.onShowApproval = onShowApproval
        statusItem.button?.image = NSImage(
            systemSymbolName: "dot.radiowaves.left.and.right",
            accessibilityDescription: "Codex Status Radar"
        )
        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Codex Status Radar", action: nil, keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "显示状态灯",
                action: #selector(showStatus),
                keyEquivalent: "s"
            )
        )
        menu.addItem(
            NSMenuItem(
                title: "显示审批测试",
                action: #selector(showApproval),
                keyEquivalent: "a"
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "退出",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        return menu
    }

    @objc private func showStatus() {
        onShowStatus()
    }

    @objc private func showApproval() {
        onShowApproval()
    }
}
