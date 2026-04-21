import Foundation

public struct ProjectStatus: Equatable, Sendable {
    public let projectName: String
    public let threadId: String?
    public let phase: CodexPhase
    public let pendingApproval: ApprovalRequestViewModel?

    public static func empty(projectName: String) -> ProjectStatus {
        ProjectStatus(
            projectName: projectName,
            threadId: nil,
            phase: .idle,
            pendingApproval: nil
        )
    }
}

public enum CodexPhase: Equatable, Sendable {
    case disconnected
    case idle
    case working
    case waitingForInput
    case waitingForApproval
    case completed
    case failed
}
