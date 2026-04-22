import Foundation

public enum CodexEventReducer {
    public static func reduce(
        _ state: ProjectStatus,
        envelope: AppServerEnvelope
    ) -> ProjectStatus {
        switch envelope.method {
        case "thread/status/changed":
            let waiting = envelope.params.activeFlags?.contains("waitingOnApproval") == true
            let phase: CodexPhase = waiting
                ? .waitingForApproval
                : phase(from: envelope.params.status)
            return ProjectStatus(
                projectName: state.projectName,
                threadId: envelope.params.threadId ?? state.threadId,
                phase: phase,
                pendingApproval: waiting ? pendingApprovalFallback(from: state) : nil
            )
        case "item/commandExecution/requestApproval":
            let projectName = PrivacyRedactor.projectName(fromPath: envelope.params.cwd)
            return ProjectStatus(
                projectName: projectName,
                threadId: envelope.params.threadId ?? state.threadId,
                phase: .waitingForApproval,
                pendingApproval: ApprovalRequestViewModel(
                    projectName: projectName,
                    reason: envelope.params.reason,
                    commandPreview: nil,
                    decisions: envelope.params.availableDecisions
                )
            )
        default:
            return state
        }
    }

    private static func phase(from status: String?) -> CodexPhase {
        switch status {
        case "idle":
            return .idle
        case "running":
            return .working
        case "waitingForInput", "waiting_for_input":
            return .waitingForInput
        case "completed":
            return .completed
        case "failed", "error":
            return .failed
        default:
            return .working
        }
    }

    private static func pendingApprovalFallback(from state: ProjectStatus) -> ApprovalRequestViewModel {
        if let pendingApproval = state.pendingApproval {
            return pendingApproval
        }

        return ApprovalRequestViewModel(
            projectName: state.projectName,
            reason: "Codex 正在等待你确认操作。请回到 Codex 处理审批。",
            commandPreview: nil,
            decisions: nil
        )
    }
}
