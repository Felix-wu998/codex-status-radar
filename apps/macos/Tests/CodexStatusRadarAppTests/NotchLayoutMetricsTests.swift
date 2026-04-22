import XCTest
@testable import CodexStatusRadarApp

final class NotchLayoutMetricsTests: XCTestCase {
    func testWindowContainerCanHoldCollapsedAndApprovalSurfaces() {
        XCTAssertGreaterThanOrEqual(NotchLayoutMetrics.windowSize.width, NotchLayoutMetrics.collapsedSize.width)
        XCTAssertGreaterThanOrEqual(NotchLayoutMetrics.windowSize.height, NotchLayoutMetrics.collapsedSize.height)
        XCTAssertGreaterThanOrEqual(NotchLayoutMetrics.windowSize.width, NotchLayoutMetrics.waitingReminderSize.width)
        XCTAssertGreaterThanOrEqual(NotchLayoutMetrics.windowSize.height, NotchLayoutMetrics.waitingReminderSize.height)
        XCTAssertGreaterThanOrEqual(NotchLayoutMetrics.windowSize.width, NotchLayoutMetrics.expandedApprovalSize.width)
        XCTAssertGreaterThanOrEqual(NotchLayoutMetrics.windowSize.height, NotchLayoutMetrics.expandedApprovalSize.height)
    }

    func testWaitingReminderSurfaceIsBetweenCollapsedAndApprovalSizes() {
        XCTAssertGreaterThan(NotchLayoutMetrics.waitingReminderSize.width, NotchLayoutMetrics.collapsedSize.width)
        XCTAssertGreaterThan(NotchLayoutMetrics.waitingReminderSize.height, NotchLayoutMetrics.collapsedSize.height)
        XCTAssertLessThan(NotchLayoutMetrics.waitingReminderSize.width, NotchLayoutMetrics.expandedApprovalSize.width)
        XCTAssertLessThan(NotchLayoutMetrics.waitingReminderSize.height, NotchLayoutMetrics.expandedApprovalSize.height)
    }

    func testApprovalSurfaceExpandsFromCollapsedHeader() {
        XCTAssertGreaterThan(NotchLayoutMetrics.expandedApprovalSize.width, NotchLayoutMetrics.collapsedSize.width)
        XCTAssertGreaterThan(NotchLayoutMetrics.expandedApprovalSize.height, NotchLayoutMetrics.collapsedSize.height)
        XCTAssertEqual(NotchLayoutMetrics.closedHeaderHeight, NotchLayoutMetrics.collapsedSize.height)
        XCTAssertLessThanOrEqual(NotchLayoutMetrics.expandedApprovalSize.height, 156)
    }
}
