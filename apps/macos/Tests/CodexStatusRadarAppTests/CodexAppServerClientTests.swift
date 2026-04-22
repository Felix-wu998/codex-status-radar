import XCTest
import CodexStatusRadarCore
@testable import CodexStatusRadarApp

final class CodexAppServerClientTests: XCTestCase {
    func testDefaultEndpointIsLocalhost8794() {
        XCTAssertEqual(
            CodexAppServerEndpoint.default.url.absoluteString,
            "ws://127.0.0.1:8794"
        )
    }

    func testMessageDecoderIgnoresRpcResponsesWithoutMethod() throws {
        let message = #"{"id":1,"result":{"ok":true}}"#

        let envelope = try CodexAppServerMessageDecoder.decodeEventText(message)

        XCTAssertNil(envelope)
    }

    func testMessageDecoderDecodesStatusEventText() throws {
        let message = """
        {
          "method": "thread/status/changed",
          "params": {
            "threadId": "thread-1",
            "status": {
              "state": "running",
              "activeFlags": ["waitingOnApproval"]
            }
          }
        }
        """

        let envelope = try XCTUnwrap(CodexAppServerMessageDecoder.decodeEventText(message))

        XCTAssertEqual(envelope.method, "thread/status/changed")
        XCTAssertEqual(envelope.params.threadId, "thread-1")
        XCTAssertEqual(envelope.params.activeFlags, ["waitingOnApproval"])
    }

    func testMessageDecoderDecodesUtf8BinaryStatusEvent() throws {
        let data = Data(
            #"{"method":"thread/status/changed","params":{"threadId":"thread-1","status":"running","activeFlags":[]}}"#.utf8
        )

        let envelope = try XCTUnwrap(CodexAppServerMessageDecoder.decodeEventMessage(.data(data)))

        XCTAssertEqual(envelope.method, "thread/status/changed")
        XCTAssertEqual(envelope.params.status, "running")
    }

    func testApprovalResponseEncodesDecisionWithOriginalRequestId() throws {
        let data = try CodexAppServerApprovalResponseEncoder.encode(
            requestId: .integer(42),
            decision: .accept
        )
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let result = object?["result"] as? [String: Any]

        XCTAssertEqual(object?["id"] as? Int, 42)
        XCTAssertEqual(result?["decision"] as? String, "accept")
    }

    func testHandshakeEncoderBuildsInitializeRequest() throws {
        let data = try CodexAppServerHandshakeEncoder.encodeInitializeRequest(id: .integer(1))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let params = try XCTUnwrap(object["params"] as? [String: Any])
        let clientInfo = try XCTUnwrap(params["clientInfo"] as? [String: Any])
        let capabilities = try XCTUnwrap(params["capabilities"] as? [String: Any])

        XCTAssertEqual(object["id"] as? Int, 1)
        XCTAssertEqual(object["method"] as? String, "initialize")
        XCTAssertEqual(clientInfo["name"] as? String, "codex-status-radar")
        XCTAssertEqual(capabilities["experimentalApi"] as? Bool, true)
    }

    func testHandshakeEncoderBuildsInitializedNotification() throws {
        let data = try CodexAppServerHandshakeEncoder.encodeInitializedNotification()
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(object?["method"] as? String, "initialized")
        XCTAssertNil(object?["id"])
    }

    func testThreadRequestEncoderBuildsLoadedListRequest() throws {
        let data = try CodexAppServerThreadRequestEncoder.encodeLoadedListRequest(id: .integer(2))
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let params = object?["params"] as? [String: Any]

        XCTAssertEqual(object?["id"] as? Int, 2)
        XCTAssertEqual(object?["method"] as? String, "thread/loaded/list")
        XCTAssertEqual(params?["limit"] as? Int, 50)
    }

    func testThreadRequestEncoderBuildsResumeRequest() throws {
        let data = try CodexAppServerThreadRequestEncoder.encodeResumeRequest(
            id: .integer(3),
            threadId: "thread-1"
        )
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let params = object?["params"] as? [String: Any]

        XCTAssertEqual(object?["id"] as? Int, 3)
        XCTAssertEqual(object?["method"] as? String, "thread/resume")
        XCTAssertEqual(params?["threadId"] as? String, "thread-1")
        XCTAssertEqual(params?["persistExtendedHistory"] as? Bool, false)
    }

    func testInboundDecoderDecodesLoadedThreadIdsResponse() throws {
        let message = #"{"id":2,"result":{"data":["thread-1","thread-2"],"nextCursor":null}}"#

        let inbound = try CodexAppServerMessageDecoder.decodeInboundText(message)

        XCTAssertEqual(inbound, .loadedThreadIds(.integer(2), ["thread-1", "thread-2"]))
    }

    @MainActor
    func testConnectionCoordinatorReconnectsAfterDisconnectWhileRunning() {
        let harness = ConnectionCoordinatorHarness()
        let coordinator = CodexAppServerConnectionCoordinator(
            reconnectDelay: 1.5,
            makeClient: harness.makeClient,
            scheduleReconnect: harness.scheduleReconnect
        )

        coordinator.start()
        XCTAssertEqual(harness.clients.count, 1)

        harness.clients[0].disconnectHandler?()
        XCTAssertEqual(harness.scheduledDelays, [1.5])

        harness.scheduledActions[0]()
        XCTAssertEqual(harness.clients.count, 2)
        XCTAssertTrue(harness.clients[1].didConnect)
    }

    @MainActor
    func testConnectionCoordinatorDoesNotReconnectAfterStop() {
        let harness = ConnectionCoordinatorHarness()
        let coordinator = CodexAppServerConnectionCoordinator(
            reconnectDelay: 1.5,
            makeClient: harness.makeClient,
            scheduleReconnect: harness.scheduleReconnect
        )

        coordinator.start()
        coordinator.stop()
        harness.clients[0].disconnectHandler?()

        XCTAssertTrue(harness.scheduledActions.isEmpty)
    }

    @MainActor
    func testConnectionCoordinatorSendsApprovalThroughCurrentClient() {
        let harness = ConnectionCoordinatorHarness()
        let coordinator = CodexAppServerConnectionCoordinator(
            reconnectDelay: 1.5,
            makeClient: harness.makeClient,
            scheduleReconnect: harness.scheduleReconnect
        )

        coordinator.start()
        coordinator.sendApprovalResponse(requestId: .integer(42), decision: .decline)

        XCTAssertEqual(harness.clients[0].sentRequestId, .integer(42))
        XCTAssertEqual(harness.clients[0].sentDecision, .decline)
    }
}

@MainActor
private final class ConnectionCoordinatorHarness {
    var clients: [MockAppServerClient] = []
    var scheduledDelays: [TimeInterval] = []
    var scheduledActions: [@MainActor () -> Void] = []

    func makeClient(
        _ endpoint: CodexAppServerEndpoint,
        _ onEvent: @escaping @MainActor (AppServerEnvelope) -> Void,
        _ onDisconnect: @escaping @MainActor () -> Void
    ) -> CodexAppServerConnecting {
        let client = MockAppServerClient(disconnectHandler: onDisconnect)
        clients.append(client)
        return client
    }

    func scheduleReconnect(
        _ delay: TimeInterval,
        _ action: @escaping @MainActor () -> Void
    ) -> ReconnectCancellation {
        scheduledDelays.append(delay)
        scheduledActions.append(action)
        return MockReconnectCancellation()
    }
}

@MainActor
private final class MockAppServerClient: CodexAppServerConnecting {
    let disconnectHandler: (@MainActor () -> Void)?
    var didConnect = false
    var didDisconnect = false
    var sentRequestId: AppServerRequestId?
    var sentDecision: ApprovalDecision?

    init(disconnectHandler: (@MainActor () -> Void)?) {
        self.disconnectHandler = disconnectHandler
    }

    func connect() {
        didConnect = true
    }

    func disconnect() {
        didDisconnect = true
    }

    func sendApprovalResponse(
        requestId: AppServerRequestId,
        decision: ApprovalDecision
    ) {
        sentRequestId = requestId
        sentDecision = decision
    }
}

private final class MockReconnectCancellation: ReconnectCancellation {
    var didCancel = false

    func cancel() {
        didCancel = true
    }
}
