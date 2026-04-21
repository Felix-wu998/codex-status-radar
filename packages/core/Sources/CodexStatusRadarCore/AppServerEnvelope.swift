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
}
