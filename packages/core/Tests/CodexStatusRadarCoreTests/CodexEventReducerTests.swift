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
        XCTAssertEqual(state.pendingApproval?.reason, "Codex 正在等待你确认操作。请回到 Codex 处理审批。")
        XCTAssertTrue(state.pendingApproval?.actions.isEmpty == true)
    }

    func testThreadStatusChangedMapsKnownStates() {
        XCTAssertEqual(reducedPhase(for: "idle"), .idle)
        XCTAssertEqual(reducedPhase(for: "running"), .working)
        XCTAssertEqual(reducedPhase(for: "waitingForInput"), .waitingForInput)
        XCTAssertEqual(reducedPhase(for: "completed"), .completed)
        XCTAssertEqual(reducedPhase(for: "failed"), .failed)
    }

    func testThreadStatusChangedClearsPendingApprovalWhenApprovalFlagDisappears() {
        let oldApproval = ApprovalRequestViewModel(
            projectName: "project",
            decisions: [.accept, .cancel]
        )
        let state = ProjectStatus(
            projectName: "project",
            threadId: "thread-1",
            phase: .waitingForApproval,
            pendingApproval: oldApproval
        )
        let envelope = AppServerEnvelope(
            id: nil,
            method: "thread/status/changed",
            params: AppServerParams(
                threadId: "thread-1",
                turnId: nil,
                itemId: nil,
                status: "running",
                activeFlags: [],
                command: nil,
                cwd: nil,
                reason: nil,
                availableDecisions: nil
            )
        )

        let reduced = CodexEventReducer.reduce(state, envelope: envelope)

        XCTAssertEqual(reduced.phase, .working)
        XCTAssertNil(reduced.pendingApproval)
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

    private func reducedPhase(for status: String) -> CodexPhase {
        let envelope = AppServerEnvelope(
            id: nil,
            method: "thread/status/changed",
            params: AppServerParams(
                threadId: "thread-1",
                turnId: nil,
                itemId: nil,
                status: status,
                activeFlags: [],
                command: nil,
                cwd: nil,
                reason: nil,
                availableDecisions: nil
            )
        )
        return CodexEventReducer.reduce(
            .empty(projectName: "project"),
            envelope: envelope
        ).phase
    }
}
