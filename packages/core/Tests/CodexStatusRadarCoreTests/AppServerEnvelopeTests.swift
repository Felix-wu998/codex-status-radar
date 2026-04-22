import XCTest
@testable import CodexStatusRadarCore

final class AppServerEnvelopeTests: XCTestCase {
    func testDecodesWaitingOnApprovalStatusChange() throws {
        let data = Data(
            """
            {
              "method": "thread/status/changed",
              "params": {
                "threadId": "thread-1",
                "status": "running",
                "activeFlags": ["waitingOnApproval"]
              }
            }
            """.utf8
        )

        let envelope = try JSONDecoder().decode(AppServerEnvelope.self, from: data)

        XCTAssertEqual(envelope.method, "thread/status/changed")
        XCTAssertEqual(envelope.params.threadId, "thread-1")
        XCTAssertEqual(envelope.params.activeFlags, ["waitingOnApproval"])
    }

    func testDecodesObservedNestedWaitingOnApprovalStatusChange() throws {
        let data = Data(
            """
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
            """.utf8
        )

        let envelope = try JSONDecoder().decode(AppServerEnvelope.self, from: data)

        XCTAssertEqual(envelope.method, "thread/status/changed")
        XCTAssertEqual(envelope.params.threadId, "thread-1")
        XCTAssertEqual(envelope.params.status, "running")
        XCTAssertEqual(envelope.params.activeFlags, ["waitingOnApproval"])
    }

    func testDecodesObservedStatusTypeField() throws {
        let data = Data(
            """
            {
              "method": "thread/status/changed",
              "params": {
                "threadId": "thread-1",
                "status": {
                  "type": "idle"
                }
              }
            }
            """.utf8
        )

        let envelope = try JSONDecoder().decode(AppServerEnvelope.self, from: data)

        XCTAssertEqual(envelope.params.status, "idle")
        XCTAssertNil(envelope.params.activeFlags)
    }

    func testDecodesCommandApprovalRequestWithAvailableDecisions() throws {
        let data = Data(
            """
            {
              "id": 42,
              "method": "item/commandExecution/requestApproval",
              "params": {
                "threadId": "thread-1",
                "turnId": "turn-1",
                "itemId": "item-1",
                "command": "touch /tmp/example.txt",
                "cwd": "/Users/example/project",
                "availableDecisions": ["accept", "cancel"]
              }
            }
            """.utf8
        )

        let envelope = try JSONDecoder().decode(AppServerEnvelope.self, from: data)

        XCTAssertEqual(envelope.id, .integer(42))
        XCTAssertEqual(envelope.method, "item/commandExecution/requestApproval")
        XCTAssertEqual(envelope.params.command, "touch /tmp/example.txt")
        XCTAssertEqual(envelope.params.availableDecisions, [.accept, .cancel])
    }

    func testDecodesStringRequestId() throws {
        let data = Data(
            """
            {
              "id": "approval-1",
              "method": "item/commandExecution/requestApproval",
              "params": {
                "threadId": "thread-1",
                "availableDecisions": ["decline"]
              }
            }
            """.utf8
        )

        let envelope = try JSONDecoder().decode(AppServerEnvelope.self, from: data)

        XCTAssertEqual(envelope.id, .string("approval-1"))
    }
}
