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

    func testDecodesCommandApprovalRequestWithAvailableDecisions() throws {
        let data = Data(
            """
            {
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

        XCTAssertEqual(envelope.method, "item/commandExecution/requestApproval")
        XCTAssertEqual(envelope.params.command, "touch /tmp/example.txt")
        XCTAssertEqual(envelope.params.availableDecisions, [.accept, .cancel])
    }
}
