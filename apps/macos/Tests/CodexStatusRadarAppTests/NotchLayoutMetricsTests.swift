import XCTest
@testable import CodexStatusRadarApp

final class NotchLayoutMetricsTests: XCTestCase {
    func testWindowContainerCanHoldCollapsedAndApprovalSurfaces() {
        XCTAssertGreaterThanOrEqual(NotchLayoutMetrics.windowSize.width, NotchLayoutMetrics.collapsedSize.width)
        XCTAssertGreaterThanOrEqual(NotchLayoutMetrics.windowSize.height, NotchLayoutMetrics.collapsedSize.height)
        XCTAssertGreaterThanOrEqual(NotchLayoutMetrics.windowSize.width, NotchLayoutMetrics.expandedApprovalSize.width)
        XCTAssertGreaterThanOrEqual(NotchLayoutMetrics.windowSize.height, NotchLayoutMetrics.expandedApprovalSize.height)
    }

    func testApprovalSurfaceExpandsFromCollapsedHeader() {
        XCTAssertGreaterThan(NotchLayoutMetrics.expandedApprovalSize.width, NotchLayoutMetrics.collapsedSize.width)
        XCTAssertGreaterThan(NotchLayoutMetrics.expandedApprovalSize.height, NotchLayoutMetrics.collapsedSize.height)
        XCTAssertEqual(NotchLayoutMetrics.closedHeaderHeight, NotchLayoutMetrics.collapsedSize.height)
        XCTAssertLessThanOrEqual(NotchLayoutMetrics.expandedApprovalSize.height, 156)
    }
}
