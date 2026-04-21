import Foundation

public struct ApprovalRequestViewModel: Equatable, Sendable {
    public let projectName: String
    public let reason: String?
    public let commandPreview: String?
    public let actions: [ApprovalAction]

    public init(
        projectName: String,
        reason: String? = nil,
        commandPreview: String? = nil,
        decisions: [ApprovalDecision]?
    ) {
        self.projectName = projectName
        self.reason = reason
        self.commandPreview = commandPreview
        self.actions = Self.actions(for: decisions)
    }

    public static func actions(for decisions: [ApprovalDecision]?) -> [ApprovalAction] {
        guard let decisions, !decisions.isEmpty else {
            return []
        }

        return decisions.map { decision in
            switch decision {
            case .accept:
                ApprovalAction(
                    title: "批准一次",
                    subtitle: nil,
                    style: .primary,
                    decision: decision
                )
            case .acceptForSession:
                ApprovalAction(
                    title: "本次会话批准",
                    subtitle: nil,
                    style: .extended,
                    decision: decision
                )
            case .acceptWithExecpolicyAmendment:
                ApprovalAction(
                    title: "本次会话批准",
                    subtitle: "允许类似命令",
                    style: .extended,
                    decision: decision
                )
            case .applyNetworkPolicyAmendment:
                ApprovalAction(
                    title: "本次会话批准",
                    subtitle: "允许网络规则",
                    style: .extended,
                    decision: decision
                )
            case .decline:
                ApprovalAction(
                    title: "拒绝",
                    subtitle: nil,
                    style: .destructive,
                    decision: decision
                )
            case .cancel:
                ApprovalAction(
                    title: "拒绝",
                    subtitle: "取消本次请求",
                    style: .destructive,
                    decision: decision
                )
            }
        }
    }
}

public struct ApprovalAction: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String?
    public let style: ApprovalActionStyle
    public let decision: ApprovalDecision

    public init(
        title: String,
        subtitle: String?,
        style: ApprovalActionStyle,
        decision: ApprovalDecision
    ) {
        self.id = Self.id(for: decision)
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.decision = decision
    }

    private static func id(for decision: ApprovalDecision) -> String {
        switch decision {
        case .accept:
            "accept"
        case .acceptForSession:
            "acceptForSession"
        case .acceptWithExecpolicyAmendment:
            "acceptWithExecpolicyAmendment"
        case .applyNetworkPolicyAmendment:
            "applyNetworkPolicyAmendment"
        case .decline:
            "decline"
        case .cancel:
            "cancel"
        }
    }
}

public enum ApprovalActionStyle: String, Equatable, Sendable {
    case primary
    case extended
    case destructive
}
