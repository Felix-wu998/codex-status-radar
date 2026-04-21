import Foundation

public enum CodexEventReducer {
    public static func reduce(
        _ state: ProjectStatus,
        envelope: AppServerEnvelope
    ) -> ProjectStatus {
        switch envelope.method {
        case "thread/status/changed":
            let waiting = envelope.params.activeFlags?.contains("waitingOnApproval") == true
            return ProjectStatus(
                projectName: state.projectName,
                threadId: envelope.params.threadId ?? state.threadId,
                phase: waiting ? .waitingForApproval : .working,
                pendingApproval: state.pendingApproval
            )
        case "item/commandExecution/requestApproval":
            return ProjectStatus(
                projectName: state.projectName,
                threadId: envelope.params.threadId ?? state.threadId,
                phase: .waitingForApproval,
                pendingApproval: ApprovalRequestViewModel(
                    projectName: state.projectName,
                    reason: nil,
                    commandPreview: nil,
                    decisions: envelope.params.availableDecisions
                )
            )
        default:
            return state
        }
    }
}
