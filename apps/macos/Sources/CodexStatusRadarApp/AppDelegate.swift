import AppKit
import CodexStatusRadarCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var notchStatusWindowController: NotchStatusWindowController?
    private var isDemoMode: Bool {
        CommandLine.arguments.contains("--demo-approval")
            || Bundle.main.bundleIdentifier?.contains(".demo") == true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        start()
    }

    func start() {
        guard notchStatusWindowController == nil else {
            return
        }

        NSApp.setActivationPolicy(.accessory)
        notchStatusWindowController = NotchStatusWindowController(isDemoMode: isDemoMode)

        if isDemoMode {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()
            DispatchQueue.main.async { [weak self] in
                self?.showApprovalFixture()
            }
        } else {
            menuBarController = MenuBarController(
                onShowStatus: { [weak self] in
                    self?.notchStatusWindowController?.showStatus(.working)
                },
                onShowApproval: { [weak self] in
                    self?.showApprovalFixture()
                }
            )
            DispatchQueue.main.async { [weak self] in
                self?.notchStatusWindowController?.showStatus(.idle)
            }
        }
    }

    private func showApprovalFixture() {
        let viewModel = ApprovalRequestViewModel(
            projectName: "codex-status-radar",
            reason: "Codex 请求执行一个需要确认的本地命令。",
            commandPreview: nil,
            decisions: [
                .accept,
                .acceptWithExecpolicyAmendment(
                    ExecpolicyAmendmentPayload(
                        execpolicyAmendment: [
                            "touch",
                            "/tmp/codex-status-radar-approval-test.txt"
                        ]
                    )
                ),
                .cancel
            ]
        )

        notchStatusWindowController?.showApproval(viewModel) { [weak self] _ in
            self?.notchStatusWindowController?.showStatus(.working)
        }
    }
}
