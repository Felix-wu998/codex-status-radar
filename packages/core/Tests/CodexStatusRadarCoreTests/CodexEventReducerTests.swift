import XCTest
@testable import CodexStatusRadarCore

final class CodexEventReducerTests: XCTestCase {
    func testWaitingOnApprovalFlagCreatesPendingApprovalPhase() {
        let envelope = AppServerEnvelope(
            method: "thread/status/changed",
            params: AppServerParams(
                threadId: "thread-1",
                turnId: nil,
                itemId: nil,
                status: "running",
                activeFlags: ["waitingOnApproval"],
                command: nil,
                cwd: nil,
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
            method: "item/commandExecution/requestApproval",
            params: AppServerParams(
                threadId: "thread-1",
                turnId: "turn-1",
                itemId: "item-1",
                status: nil,
                activeFlags: nil,
                command: "touch /tmp/example.txt",
                cwd: "/Users/example/project",
                availableDecisions: [.accept, .cancel]
            )
        )

        var state = ProjectStatus.empty(projectName: "project")
        state = CodexEventReducer.reduce(state, envelope: envelope)

        XCTAssertEqual(state.phase, .waitingForApproval)
        XCTAssertEqual(state.pendingApproval?.actions.map(\.title), ["批准一次", "拒绝"])
        XCTAssertNil(state.pendingApproval?.commandPreview)
    }
}
