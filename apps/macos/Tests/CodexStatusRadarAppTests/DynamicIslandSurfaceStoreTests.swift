import XCTest
import CodexStatusRadarCore
@testable import CodexStatusRadarApp

@MainActor
final class DynamicIslandSurfaceStoreTests: XCTestCase {
    func testShowStatusUsesCollapsedMode() {
        let store = DynamicIslandSurfaceStore()

        store.showStatus(.working)

        XCTAssertEqual(store.mode, .collapsed(.working))
        XCTAssertFalse(store.isInteractive)
    }

    func testShowApprovalUsesExpandedApprovalMode() {
        let store = DynamicIslandSurfaceStore()
        let approval = ApprovalRequestViewModel(
            projectName: "codex-status-radar",
            reason: "需要审批",
            commandPreview: nil,
            decisions: [.accept, .cancel]
        )

        store.showApproval(approval) { _ in }

        XCTAssertEqual(store.mode, .approval(approval))
        XCTAssertTrue(store.isInteractive)
    }

    func testSelectingApprovalActionReturnsToWorkingCollapsedMode() throws {
        let store = DynamicIslandSurfaceStore()
        let approval = ApprovalRequestViewModel(
            projectName: "codex-status-radar",
            decisions: [.accept, .cancel]
        )
        var selectedAction: ApprovalAction?

        store.showApproval(approval) { action in
            selectedAction = action
        }
        let firstAction = try XCTUnwrap(store.currentApprovalActions.first)
        store.selectApprovalAction(firstAction)

        XCTAssertEqual(selectedAction, firstAction)
        XCTAssertEqual(store.mode, .collapsed(.working))
        XCTAssertFalse(store.isInteractive)
    }
}
