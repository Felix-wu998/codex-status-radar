import XCTest
@testable import CodexStatusRadarCore

final class ApprovalDecisionMapperTests: XCTestCase {
    func testMapsObservedCommandApprovalDecisionsToNativeThreeActions() throws {
        let data = Data(
            """
            [
              "accept",
              {
                "acceptWithExecpolicyAmendment": {
                  "execpolicy_amendment": [
                    "touch",
                    "/tmp/codex-status-radar-approval-test.txt"
                  ]
                }
              },
              "cancel"
            ]
            """.utf8
        )

        let decisions = try JSONDecoder().decode([ApprovalDecision].self, from: data)
        let actions = ApprovalRequestViewModel.actions(for: decisions)

        XCTAssertEqual(actions.map(\.title), ["批准一次", "本次会话批准", "拒绝"])
        XCTAssertEqual(actions.map(\.style), [.primary, .extended, .destructive])
        XCTAssertNil(actions[0].subtitle)
        XCTAssertEqual(actions[1].subtitle, "允许类似命令")
        XCTAssertEqual(actions[2].subtitle, "取消本次请求")
        XCTAssertEqual(actions.map(\.decision), decisions)
    }

    func testMapsSessionApprovalDecisionWithoutChangingPayload() {
        let decisions: [ApprovalDecision] = [.accept, .acceptForSession, .decline]

        let actions = ApprovalRequestViewModel.actions(for: decisions)

        XCTAssertEqual(actions.map(\.title), ["批准一次", "本次会话批准", "拒绝"])
        XCTAssertEqual(actions.map(\.style), [.primary, .extended, .destructive])
        XCTAssertEqual(actions.map(\.decision), decisions)
    }

    func testReturnsNoActionsWhenProtocolDoesNotProvideDecisions() {
        XCTAssertEqual(ApprovalRequestViewModel.actions(for: nil), [])
        XCTAssertEqual(ApprovalRequestViewModel.actions(for: []), [])
    }
}
