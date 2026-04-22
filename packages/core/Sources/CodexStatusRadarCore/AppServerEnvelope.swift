import Foundation

public struct AppServerEnvelope: Decodable, Equatable, Sendable {
    public let id: AppServerRequestId?
    public let method: String
    public let params: AppServerParams
}

public enum AppServerRequestId: Codable, Equatable, Hashable, Sendable {
    case integer(Int)
    case string(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let integer = try? container.decode(Int.self) {
            self = .integer(integer)
            return
        }
        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "App-server request id must be an integer or string."
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .integer(let integer):
            try container.encode(integer)
        case .string(let string):
            try container.encode(string)
        }
    }
}

public struct AppServerParams: Decodable, Equatable, Sendable {
    public let threadId: String?
    public let turnId: String?
    public let itemId: String?
    public let status: String?
    public let activeFlags: [String]?
    public let command: String?
    public let cwd: String?
    public let reason: String?
    public let availableDecisions: [ApprovalDecision]?

    enum CodingKeys: String, CodingKey {
        case threadId
        case turnId
        case itemId
        case status
        case activeFlags
        case command
        case cwd
        case reason
        case availableDecisions
    }

    public init(
        threadId: String?,
        turnId: String?,
        itemId: String?,
        status: String?,
        activeFlags: [String]?,
        command: String?,
        cwd: String?,
        reason: String?,
        availableDecisions: [ApprovalDecision]?
    ) {
        self.threadId = threadId
        self.turnId = turnId
        self.itemId = itemId
        self.status = status
        self.activeFlags = activeFlags
        self.command = command
        self.cwd = cwd
        self.reason = reason
        self.availableDecisions = availableDecisions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedStatus = try? container.decode(AppServerStatusPayload.self, forKey: .status)

        self.threadId = try container.decodeIfPresent(String.self, forKey: .threadId)
        self.turnId = try container.decodeIfPresent(String.self, forKey: .turnId)
        self.itemId = try container.decodeIfPresent(String.self, forKey: .itemId)
        self.status = (try? container.decodeIfPresent(String.self, forKey: .status))
            ?? nestedStatus?.state
            ?? nestedStatus?.type
        self.activeFlags = try container.decodeIfPresent([String].self, forKey: .activeFlags)
            ?? nestedStatus?.activeFlags
        self.command = try container.decodeIfPresent(String.self, forKey: .command)
        self.cwd = try container.decodeIfPresent(String.self, forKey: .cwd)
        self.reason = try container.decodeIfPresent(String.self, forKey: .reason)
        self.availableDecisions = try container.decodeIfPresent(
            [ApprovalDecision].self,
            forKey: .availableDecisions
        )
    }
}

private struct AppServerStatusPayload: Decodable {
    let type: String?
    let state: String?
    let activeFlags: [String]?
}
