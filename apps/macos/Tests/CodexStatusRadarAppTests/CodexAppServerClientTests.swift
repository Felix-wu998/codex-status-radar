import XCTest
@testable import CodexStatusRadarApp

final class CodexAppServerClientTests: XCTestCase {
    func testDefaultEndpointIsLocalhost8794() {
        XCTAssertEqual(
            CodexAppServerEndpoint.default.url.absoluteString,
            "ws://127.0.0.1:8794"
        )
    }
}
