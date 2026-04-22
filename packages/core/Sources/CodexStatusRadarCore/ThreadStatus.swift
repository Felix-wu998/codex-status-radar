import Foundation

public struct ProjectStatus: Equatable, Sendable {
    public let projectName: String
    public let threadId: String?
    public let phase: CodexPhase
    public let pendingApproval: ApprovalRequestViewModel?

    public init(
        projectName: String,
        threadId: String?,
        phase: CodexPhase,
        pendingApproval: ApprovalRequestViewModel?
    ) {
        self.projectName = projectName
        self.threadId = threadId
        self.phase = phase
        self.pendingApproval = pendingApproval
    }

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
