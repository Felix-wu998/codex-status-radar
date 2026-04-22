import XCTest
@testable import CodexStatusRadarCore

final class CodexEventReducerTests: XCTestCase {
    func testWaitingOnApprovalFlagCreatesPendingApprovalPhase() {
        let envelope = AppServerEnvelope(
            id: nil,
            method: "thread/status/changed",
            params: AppServerParams(
                threadId: "thread-1",
                turnId: nil,
                itemId: nil,
                status: "running",
                activeFlags: ["waitingOnApproval"],
                command: nil,
                cwd: nil,
                reason: nil,
                availableDecisions: nil
            )
        )

        var state = ProjectStatus.empty(projectName: "codex-status-radar")
        state = CodexEventReducer.reduce(state, envelope: envelope)

        XCTAssertEqual(state.phase, .waitingForApproval)
        XCTAssertEqual(state.threadId, "thread-1")
    }

    func testApprovalRequestStoresActionsWithoutShowingCommandByDefault() {
        let envelope = AppServerEnvelope(
            id: .integer(42),
            method: "item/commandExecution/requestApproval",
            params: AppServerParams(
                threadId: "thread-1",
                turnId: "turn-1",
                itemId: "item-1",
                status: nil,
                activeFlags: nil,
                command: "touch /tmp/example.txt",
                cwd: "/Users/example/project",
                reason: "命令需要审批",
                availableDecisions: [.accept, .cancel]
            )
        )

        var state = ProjectStatus.empty(projectName: "old-project")
        state = CodexEventReducer.reduce(state, envelope: envelope)

        XCTAssertEqual(state.phase, .waitingForApproval)
        XCTAssertEqual(state.projectName, "project")
        XCTAssertEqual(state.pendingApproval?.projectName, "project")
        XCTAssertEqual(state.pendingApproval?.reason, "命令需要审批")
        XCTAssertEqual(state.pendingApproval?.actions.map(\.title), ["批准一次", "拒绝"])
        XCTAssertNil(state.pendingApproval?.commandPreview)
    }
}
