import Foundation
import CodexStatusRadarCore

struct CodexAppServerEndpoint: Equatable {
    let url: URL

    static let `default` = CodexAppServerEndpoint(
        url: URL(string: "ws://127.0.0.1:8794")!
    )
}

@MainActor
final class CodexAppServerClient {
    private let endpoint: CodexAppServerEndpoint
    private let onEvent: @MainActor (AppServerEnvelope) -> Void
    private let onDisconnect: @MainActor () -> Void
    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?

    init(
        endpoint: CodexAppServerEndpoint = .default,
        onEvent: @escaping @MainActor (AppServerEnvelope) -> Void = { _ in },
        onDisconnect: @escaping @MainActor () -> Void = {}
    ) {
        self.endpoint = endpoint
        self.onEvent = onEvent
        self.onDisconnect = onDisconnect
    }

    func connect() {
        disconnect()

        let socketTask = URLSession.shared.webSocketTask(with: endpoint.url)
        task = socketTask
        socketTask.resume()

        receiveTask = Task { [weak self] in
            guard let self else { return }
            await self.receiveLoop(socketTask)
        }
    }

    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    func sendApprovalResponse(
        requestId: AppServerRequestId,
        decision: ApprovalDecision
    ) {
        guard let task else {
            return
        }

        do {
            let data = try CodexAppServerApprovalResponseEncoder.encode(
                requestId: requestId,
                decision: decision
            )
            guard let text = String(data: data, encoding: .utf8) else {
                return
            }
            task.send(.string(text)) { _ in }
        } catch {
            return
        }
    }

    private func receiveLoop(_ task: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                guard let envelope = try CodexAppServerMessageDecoder.decodeEventMessage(message) else {
                    continue
                }
                onEvent(envelope)
            } catch {
                onDisconnect()
                return
            }
        }
    }
}

enum CodexAppServerMessageDecoder {
    static func decodeEventMessage(
        _ message: URLSessionWebSocketTask.Message
    ) throws -> AppServerEnvelope? {
        switch message {
        case .string(let text):
            return try decodeEventText(text)
        case .data(let data):
            guard let text = String(data: data, encoding: .utf8) else {
                return nil
            }
            return try decodeEventText(text)
        @unknown default:
            return nil
        }
    }

    static func decodeEventText(_ text: String) throws -> AppServerEnvelope? {
        let data = Data(text.utf8)
        let probe = try JSONDecoder().decode(MethodProbe.self, from: data)
        guard probe.method != nil else {
            return nil
        }
        return try JSONDecoder().decode(AppServerEnvelope.self, from: data)
    }
}

private struct MethodProbe: Decodable {
    let method: String?
}

enum CodexAppServerApprovalResponseEncoder {
    static func encode(
        requestId: AppServerRequestId,
        decision: ApprovalDecision
    ) throws -> Data {
        try JSONEncoder().encode(
            ApprovalResponse(
                id: requestId,
                result: ApprovalResponseResult(decision: decision)
            )
        )
    }
}

private struct ApprovalResponse: Encodable {
    let id: AppServerRequestId
    let result: ApprovalResponseResult
}

private struct ApprovalResponseResult: Encodable {
    let decision: ApprovalDecision
}
