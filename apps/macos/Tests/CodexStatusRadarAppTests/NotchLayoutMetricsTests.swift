import XCTest
@testable import CodexStatusRadarApp

final class NotchLayoutMetricsTests: XCTestCase {
    func testApprovalIslandIsWiderAndTallerThanStatusPill() {
        XCTAssertGreaterThan(NotchLayoutMetrics.approvalSize.width, NotchLayoutMetrics.statusSize.width)
        XCTAssertGreaterThan(NotchLayoutMetrics.approvalSize.height, NotchLayoutMetrics.statusSize.height)
    }

    func testApprovalIslandKeepsCompactNotchLikeHeight() {
        XCTAssertLessThanOrEqual(NotchLayoutMetrics.approvalSize.height, 118)
    }
}
