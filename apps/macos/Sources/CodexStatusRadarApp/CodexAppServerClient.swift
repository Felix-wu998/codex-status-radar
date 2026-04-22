import Foundation
import CodexStatusRadarCore

struct CodexAppServerEndpoint: Equatable {
    let url: URL

    static let `default` = CodexAppServerEndpoint(
        url: URL(string: "ws://127.0.0.1:8794")!
    )
}

@MainActor
protocol CodexAppServerConnecting: AnyObject {
    func connect()
    func disconnect()
    func sendApprovalResponse(
        requestId: AppServerRequestId,
        decision: ApprovalDecision
    )
}

protocol ReconnectCancellation: AnyObject {
    func cancel()
}

@MainActor
final class CodexAppServerConnectionCoordinator {
    typealias ClientFactory = (
        CodexAppServerEndpoint,
        @escaping @MainActor (AppServerEnvelope) -> Void,
        @escaping @MainActor () -> Void
    ) -> CodexAppServerConnecting
    typealias ReconnectScheduler = (
        TimeInterval,
        @escaping @MainActor () -> Void
    ) -> ReconnectCancellation

    private let endpoint: CodexAppServerEndpoint
    private let reconnectDelay: TimeInterval
    private let onEvent: @MainActor (AppServerEnvelope) -> Void
    private let onDisconnect: @MainActor () -> Void
    private let makeClient: ClientFactory
    private let scheduleReconnect: ReconnectScheduler
    private var client: CodexAppServerConnecting?
    private var reconnectCancellation: ReconnectCancellation?
    private var isRunning = false

    init(
        endpoint: CodexAppServerEndpoint = .default,
        reconnectDelay: TimeInterval = 2,
        onEvent: @escaping @MainActor (AppServerEnvelope) -> Void = { _ in },
        onDisconnect: @escaping @MainActor () -> Void = {},
        makeClient: @escaping ClientFactory = { endpoint, onEvent, onDisconnect in
            CodexAppServerClient(
                endpoint: endpoint,
                onEvent: onEvent,
                onDisconnect: onDisconnect
            )
        },
        scheduleReconnect: @escaping ReconnectScheduler = { delay, action in
            TimerReconnectCancellation(
                timer: Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
                    Task { @MainActor in
                        action()
                    }
                }
            )
        }
    ) {
        self.endpoint = endpoint
        self.reconnectDelay = reconnectDelay
        self.onEvent = onEvent
        self.onDisconnect = onDisconnect
        self.makeClient = makeClient
        self.scheduleReconnect = scheduleReconnect
    }

    func start() {
        guard !isRunning else {
            return
        }
        isRunning = true
        connect()
    }

    func stop() {
        isRunning = false
        reconnectCancellation?.cancel()
        reconnectCancellation = nil
        client?.disconnect()
        client = nil
    }

    func sendApprovalResponse(
        requestId: AppServerRequestId,
        decision: ApprovalDecision
    ) {
        client?.sendApprovalResponse(requestId: requestId, decision: decision)
    }

    private func connect() {
        reconnectCancellation?.cancel()
        reconnectCancellation = nil

        let nextClient = makeClient(
            endpoint,
            onEvent,
            { [weak self] in
                self?.handleDisconnect()
            }
        )
        client = nextClient
        nextClient.connect()
    }

    private func handleDisconnect() {
        client = nil
        onDisconnect()

        guard isRunning else {
            return
        }

        reconnectCancellation = scheduleReconnect(reconnectDelay) { [weak self] in
            guard let self, self.isRunning else {
                return
            }
            self.connect()
        }
    }
}

private final class TimerReconnectCancellation: ReconnectCancellation {
    private let timer: Timer

    init(timer: Timer) {
        self.timer = timer
    }

    func cancel() {
        timer.invalidate()
    }
}

@MainActor
final class CodexAppServerClient: CodexAppServerConnecting {
    private let endpoint: CodexAppServerEndpoint
    private let onEvent: @MainActor (AppServerEnvelope) -> Void
    private let onDisconnect: @MainActor () -> Void
    private var task: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var threadDiscoveryTimer: Timer?
    private var nextRequestId = 2
    private var pendingLoadedListRequestIds = Set<AppServerRequestId>()
    private var subscribedThreadIds = Set<String>()

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
        debugLog("connect \(endpoint.url.absoluteString)")

        let socketTask = URLSession.shared.webSocketTask(with: endpoint.url)
        task = socketTask
        socketTask.resume()
        sendStartupHandshake(on: socketTask)

        receiveTask = Task { [weak self] in
            guard let self else { return }
            await self.receiveLoop(socketTask)
        }
    }

    func disconnect() {
        receiveTask?.cancel()
        receiveTask = nil
        threadDiscoveryTimer?.invalidate()
        threadDiscoveryTimer = nil
        pendingLoadedListRequestIds.removeAll()
        subscribedThreadIds.removeAll()
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

    private func sendStartupHandshake(on task: URLSessionWebSocketTask) {
        do {
            let initializeData = try CodexAppServerHandshakeEncoder.encodeInitializeRequest(id: .integer(1))
            let initializedData = try CodexAppServerHandshakeEncoder.encodeInitializedNotification()
            guard
                let initializeText = String(data: initializeData, encoding: .utf8),
                let initializedText = String(data: initializedData, encoding: .utf8)
            else {
                return
            }

            task.send(.string(initializeText)) { _ in
                task.send(.string(initializedText)) { [weak self] _ in
                    Task { @MainActor in
                        self?.startThreadDiscovery(on: task)
                    }
                }
            }
        } catch {
            return
        }
    }

    private func startThreadDiscovery(on task: URLSessionWebSocketTask) {
        guard self.task === task else {
            return
        }

        debugLog("start thread discovery")
        sendLoadedThreadListRequest()
        threadDiscoveryTimer?.invalidate()
        threadDiscoveryTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendLoadedThreadListRequest()
            }
        }
    }

    private func receiveLoop(_ task: URLSessionWebSocketTask) async {
        while !Task.isCancelled {
            do {
                let message = try await task.receive()
                switch try CodexAppServerMessageDecoder.decodeInboundMessage(message) {
                case .event(let envelope):
                    onEvent(envelope)
                case .loadedThreadIds(let requestId, let threadIds):
                    guard pendingLoadedListRequestIds.remove(requestId) != nil else {
                        continue
                    }
                    subscribeToLoadedThreads(threadIds)
                case .ignored:
                    continue
                }
            } catch {
                onDisconnect()
                return
            }
        }
    }

    private func sendLoadedThreadListRequest() {
        guard let task else {
            return
        }
        let requestId = makeRequestId()
        do {
            let data = try CodexAppServerThreadRequestEncoder.encodeLoadedListRequest(id: requestId)
            guard let text = String(data: data, encoding: .utf8) else {
                return
            }
            pendingLoadedListRequestIds.insert(requestId)
            debugLog("send thread/loaded/list")
            task.send(.string(text)) { _ in }
        } catch {
            return
        }
    }

    private func subscribeToLoadedThreads(_ threadIds: [String]) {
        for threadId in threadIds where !subscribedThreadIds.contains(threadId) {
            sendThreadResumeRequest(threadId: threadId)
        }
    }

    private func sendThreadResumeRequest(threadId: String) {
        guard let task else {
            return
        }

        let requestId = makeRequestId()
        do {
            let data = try CodexAppServerThreadRequestEncoder.encodeResumeRequest(
                id: requestId,
                threadId: threadId
            )
            guard let text = String(data: data, encoding: .utf8) else {
                return
            }
            subscribedThreadIds.insert(threadId)
            debugLog("send thread/resume \(threadId)")
            task.send(.string(text)) { _ in }
        } catch {
            return
        }
    }

    private func makeRequestId() -> AppServerRequestId {
        defer { nextRequestId += 1 }
        return .integer(nextRequestId)
    }

    private func debugLog(_ message: String) {
        guard ProcessInfo.processInfo.environment["CODEX_STATUS_RADAR_DEBUG_LOG"] == "1" else {
            return
        }
        print("[codex-status-radar] \(message)")
        fflush(stdout)
    }
}

enum CodexAppServerInboundMessage: Equatable {
    case event(AppServerEnvelope)
    case loadedThreadIds(AppServerRequestId, [String])
    case ignored
}

enum CodexAppServerMessageDecoder {
    static func decodeInboundMessage(
        _ message: URLSessionWebSocketTask.Message
    ) throws -> CodexAppServerInboundMessage {
        switch message {
        case .string(let text):
            return try decodeInboundText(text)
        case .data(let data):
            guard let text = String(data: data, encoding: .utf8) else {
                return .ignored
            }
            return try decodeInboundText(text)
        @unknown default:
            return .ignored
        }
    }

    static func decodeInboundText(_ text: String) throws -> CodexAppServerInboundMessage {
        if let envelope = try decodeEventText(text) {
            return .event(envelope)
        }
        if let response = try? JSONDecoder().decode(ThreadLoadedListResponseEnvelope.self, from: Data(text.utf8)) {
            return .loadedThreadIds(response.id, response.result.data)
        }
        return .ignored
    }

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

private struct ThreadLoadedListResponseEnvelope: Decodable {
    let id: AppServerRequestId
    let result: ThreadLoadedListResult
}

private struct ThreadLoadedListResult: Decodable {
    let data: [String]
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

enum CodexAppServerHandshakeEncoder {
    static func encodeInitializeRequest(id: AppServerRequestId) throws -> Data {
        try JSONEncoder().encode(
            InitializeRequest(
                id: id,
                method: "initialize",
                params: InitializeParams(
                    clientInfo: ClientInfo(
                        name: "codex-status-radar",
                        title: "Codex Status Radar",
                        version: "0.1.0"
                    ),
                    capabilities: ClientCapabilities(experimentalApi: true)
                )
            )
        )
    }

    static func encodeInitializedNotification() throws -> Data {
        try JSONEncoder().encode(InitializedNotification(method: "initialized"))
    }
}

private struct InitializeRequest: Encodable {
    let id: AppServerRequestId
    let method: String
    let params: InitializeParams
}

private struct InitializeParams: Encodable {
    let clientInfo: ClientInfo
    let capabilities: ClientCapabilities
}

private struct ClientInfo: Encodable {
    let name: String
    let title: String
    let version: String
}

private struct ClientCapabilities: Encodable {
    let experimentalApi: Bool
}

private struct InitializedNotification: Encodable {
    let method: String
}

enum CodexAppServerThreadRequestEncoder {
    static func encodeLoadedListRequest(id: AppServerRequestId) throws -> Data {
        try JSONEncoder().encode(
            LoadedListRequest(
                id: id,
                method: "thread/loaded/list",
                params: LoadedListParams(cursor: nil, limit: 50)
            )
        )
    }

    static func encodeResumeRequest(
        id: AppServerRequestId,
        threadId: String
    ) throws -> Data {
        try JSONEncoder().encode(
            ResumeRequest(
                id: id,
                method: "thread/resume",
                params: ResumeParams(
                    threadId: threadId,
                    persistExtendedHistory: false
                )
            )
        )
    }
}

private struct LoadedListRequest: Encodable {
    let id: AppServerRequestId
    let method: String
    let params: LoadedListParams
}

private struct LoadedListParams: Encodable {
    let cursor: String?
    let limit: Int
}

private struct ResumeRequest: Encodable {
    let id: AppServerRequestId
    let method: String
    let params: ResumeParams
}

private struct ResumeParams: Encodable {
    let threadId: String
    let persistExtendedHistory: Bool
}
