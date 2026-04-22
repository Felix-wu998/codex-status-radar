import Foundation

public struct AppServerEnvelope: Decodable, Equatable, Sendable {
    public let method: String
    public let params: AppServerParams
}

public struct AppServerParams: Decodable, Equatable, Sendable {
    public let threadId: String?
    public let turnId: String?
    public let itemId: String?
    public let status: String?
    public let activeFlags: [String]?
    public let command: String?
    public let cwd: String?
    public let availableDecisions: [ApprovalDecision]?

    enum CodingKeys: String, CodingKey {
        case threadId
        case turnId
        case itemId
        case status
        case activeFlags
        case command
        case cwd
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
        availableDecisions: [ApprovalDecision]?
    ) {
        self.threadId = threadId
        self.turnId = turnId
        self.itemId = itemId
        self.status = status
        self.activeFlags = activeFlags
        self.command = command
        self.cwd = cwd
        self.availableDecisions = availableDecisions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedStatus = try? container.decode(AppServerStatusPayload.self, forKey: .status)

        self.threadId = try container.decodeIfPresent(String.self, forKey: .threadId)
        self.turnId = try container.decodeIfPresent(String.self, forKey: .turnId)
        self.itemId = try container.decodeIfPresent(String.self, forKey: .itemId)
        self.status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? nestedStatus?.state
        self.activeFlags = try container.decodeIfPresent([String].self, forKey: .activeFlags)
            ?? nestedStatus?.activeFlags
        self.command = try container.decodeIfPresent(String.self, forKey: .command)
        self.cwd = try container.decodeIfPresent(String.self, forKey: .cwd)
        self.availableDecisions = try container.decodeIfPresent(
            [ApprovalDecision].self,
            forKey: .availableDecisions
        )
    }
}

private struct AppServerStatusPayload: Decodable {
    let state: String?
    let activeFlags: [String]?
}
