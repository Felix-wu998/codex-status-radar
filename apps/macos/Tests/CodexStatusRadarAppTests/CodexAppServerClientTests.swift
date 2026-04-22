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
}
