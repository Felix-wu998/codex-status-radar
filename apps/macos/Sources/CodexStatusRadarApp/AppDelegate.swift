import AppKit
import CodexStatusRadarCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var notchStatusWindowController: NotchStatusWindowController?
    private var appServerClient: CodexAppServerClient?
    private var projectStatus = ProjectStatus.empty(projectName: "Codex")
    private var currentApprovalRequestId: AppServerRequestId?
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                NSApp.activate(ignoringOtherApps: true)
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
            connectAppServer()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        appServerClient?.disconnect()
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

    private func connectAppServer() {
        let client = CodexAppServerClient(
            onEvent: { [weak self] envelope in
                self?.handleAppServerEvent(envelope)
            },
            onDisconnect: { [weak self] in
                self?.projectStatus = ProjectStatus(
                    projectName: self?.projectStatus.projectName ?? "Codex",
                    threadId: self?.projectStatus.threadId,
                    phase: .disconnected,
                    pendingApproval: nil
                )
                self?.currentApprovalRequestId = nil
                self?.notchStatusWindowController?.showStatus(.disconnected)
            }
        )
        appServerClient = client
        client.connect()
    }

    private func handleAppServerEvent(_ envelope: AppServerEnvelope) {
        projectStatus = CodexEventReducer.reduce(projectStatus, envelope: envelope)

        if envelope.method == "item/commandExecution/requestApproval" {
            currentApprovalRequestId = envelope.id
        }

        render(projectStatus)
    }

    private func render(_ status: ProjectStatus) {
        if let pendingApproval = status.pendingApproval {
            notchStatusWindowController?.showApproval(pendingApproval) { [weak self] action in
                guard let self else {
                    return
                }
                if let requestId = currentApprovalRequestId {
                    appServerClient?.sendApprovalResponse(
                        requestId: requestId,
                        decision: action.decision
                    )
                }
                currentApprovalRequestId = nil
                projectStatus = ProjectStatus(
                    projectName: status.projectName,
                    threadId: status.threadId,
                    phase: .working,
                    pendingApproval: nil
                )
                notchStatusWindowController?.showStatus(.working)
            }
        } else {
            notchStatusWindowController?.showStatus(status.phase)
        }
    }
}
