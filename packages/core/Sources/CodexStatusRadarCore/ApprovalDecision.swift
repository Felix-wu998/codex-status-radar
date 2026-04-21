import Foundation

public enum ApprovalDecision: Codable, Equatable, Sendable {
    case accept
    case acceptForSession
    case acceptWithExecpolicyAmendment(ExecpolicyAmendmentPayload)
    case applyNetworkPolicyAmendment(NetworkPolicyAmendmentPayload)
    case decline
    case cancel

    public init(from decoder: Decoder) throws {
        if let stringDecision = try? decoder.singleValueContainer().decode(String.self) {
            switch stringDecision {
            case "accept":
                self = .accept
            case "acceptForSession":
                self = .acceptForSession
            case "decline":
                self = .decline
            case "cancel":
                self = .cancel
            default:
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unknown approval decision: \(stringDecision)"
                    )
                )
            }
            return
        }

        let container = try decoder.container(keyedBy: ApprovalDecisionCodingKey.self)
        if container.contains(.acceptWithExecpolicyAmendment) {
            self = .acceptWithExecpolicyAmendment(
                try container.decode(
                    ExecpolicyAmendmentPayload.self,
                    forKey: .acceptWithExecpolicyAmendment
                )
            )
            return
        }

        if container.contains(.applyNetworkPolicyAmendment) {
            self = .applyNetworkPolicyAmendment(
                try container.decode(
                    NetworkPolicyAmendmentPayload.self,
                    forKey: .applyNetworkPolicyAmendment
                )
            )
            return
        }

        throw DecodingError.dataCorrupted(
            .init(
                codingPath: decoder.codingPath,
                debugDescription: "Unknown approval decision object."
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .accept:
            var container = encoder.singleValueContainer()
            try container.encode("accept")
        case .acceptForSession:
            var container = encoder.singleValueContainer()
            try container.encode("acceptForSession")
        case let .acceptWithExecpolicyAmendment(payload):
            var container = encoder.container(keyedBy: ApprovalDecisionCodingKey.self)
            try container.encode(payload, forKey: .acceptWithExecpolicyAmendment)
        case let .applyNetworkPolicyAmendment(payload):
            var container = encoder.container(keyedBy: ApprovalDecisionCodingKey.self)
            try container.encode(payload, forKey: .applyNetworkPolicyAmendment)
        case .decline:
            var container = encoder.singleValueContainer()
            try container.encode("decline")
        case .cancel:
            var container = encoder.singleValueContainer()
            try container.encode("cancel")
        }
    }
}

public struct ExecpolicyAmendmentPayload: Codable, Equatable, Sendable {
    public let execpolicyAmendment: [String]

    public init(execpolicyAmendment: [String]) {
        self.execpolicyAmendment = execpolicyAmendment
    }

    private enum CodingKeys: String, CodingKey {
        case execpolicyAmendment = "execpolicy_amendment"
    }
}

public struct NetworkPolicyAmendmentPayload: Codable, Equatable, Sendable {
    public let networkPolicyAmendment: NetworkPolicyAmendment

    public init(networkPolicyAmendment: NetworkPolicyAmendment) {
        self.networkPolicyAmendment = networkPolicyAmendment
    }

    private enum CodingKeys: String, CodingKey {
        case networkPolicyAmendment = "network_policy_amendment"
    }
}

public struct NetworkPolicyAmendment: Codable, Equatable, Sendable {
    public let host: String
    public let action: String

    public init(host: String, action: String) {
        self.host = host
        self.action = action
    }
}

private enum ApprovalDecisionCodingKey: String, CodingKey {
    case acceptWithExecpolicyAmendment
    case applyNetworkPolicyAmendment
}
