import CodexStatusRadarCore
import SwiftUI

struct NotchStatusView: View {
    let phase: CodexPhase

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.22))
                    .frame(width: 18, height: 18)
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .shadow(color: color.opacity(0.9), radius: 5)
            }

            Text(shortLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
        }
        .padding(.horizontal, 13)
        .frame(width: NotchLayoutMetrics.statusSize.width, height: NotchLayoutMetrics.statusSize.height)
        .background(.black.opacity(0.88))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
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
