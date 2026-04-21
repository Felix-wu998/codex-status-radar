import CodexStatusRadarCore
import SwiftUI

struct NotchStatusView: View {
    let phase: CodexPhase

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .shadow(color: color.opacity(0.75), radius: 6)

            Text(shortLabel)
                .font(.caption2)
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.black.opacity(0.68))
        .clipShape(Capsule())
        .accessibilityLabel(accessibilityLabel)
    }

    private var color: Color {
        switch phase {
        case .disconnected, .failed:
            return .red
        case .idle, .completed:
            return .gray
        case .working:
            return .green
        case .waitingForInput:
            return .yellow
        case .waitingForApproval:
            return .orange
        }
    }

    private var accessibilityLabel: String {
        switch phase {
        case .disconnected:
            return "Codex 状态：未连接"
        case .idle:
            return "Codex 状态：空闲"
        case .working:
            return "Codex 状态：工作中"
        case .waitingForInput:
            return "Codex 状态：等待输入"
        case .waitingForApproval:
            return "Codex 状态：等待审批"
        case .completed:
            return "Codex 状态：已完成"
        case .failed:
            return "Codex 状态：异常"
        }
    }

    private var shortLabel: String {
        switch phase {
        case .disconnected:
            return "未连接"
        case .idle:
            return "待命"
        case .working:
            return "运行中"
        case .waitingForInput:
            return "待输入"
        case .waitingForApproval:
            return "待审批"
        case .completed:
            return "完成"
        case .failed:
            return "异常"
        }
    }
}
