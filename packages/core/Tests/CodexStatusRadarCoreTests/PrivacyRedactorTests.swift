import XCTest
@testable import CodexStatusRadarCore

final class PrivacyRedactorTests: XCTestCase {
    func testProjectNameUsesLastPathComponentOnly() {
        XCTAssertEqual(
            PrivacyRedactor.projectName(fromPath: "/Users/example/SecretClientApp"),
            "SecretClientApp"
        )
    }

    func testProjectNameFallsBackWhenPathIsMissing() {
        XCTAssertEqual(
            PrivacyRedactor.projectName(fromPath: nil),
            "Unknown Project"
        )
    }

    func testTelemetryPathBucketDoesNotExposeProjectName() {
        XCTAssertEqual(
            PrivacyRedactor.telemetryPathBucket(fromPath: "/Users/example/SecretClientApp"),
            "local-project"
        )
    }

    func testTelemetryPathBucketFallsBackWhenPathIsMissing() {
        XCTAssertEqual(
            PrivacyRedactor.telemetryPathBucket(fromPath: nil),
            "unknown"
        )
    }
}
