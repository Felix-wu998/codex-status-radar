import CodexStatusRadarCore
import SwiftUI

enum DynamicIslandSurfaceMode: Equatable {
    case collapsed(CodexPhase)
    case waitingReminder(ApprovalRequestViewModel)
    case approval(ApprovalRequestViewModel)
}

@MainActor
final class DynamicIslandSurfaceStore: ObservableObject {
    @Published private(set) var mode: DynamicIslandSurfaceMode = .collapsed(.idle)
    private var onApprovalSelect: ((ApprovalAction) -> Void)?

    var isInteractive: Bool {
        switch mode {
        case let .approval(viewModel):
            return !viewModel.actions.isEmpty
        case .collapsed, .waitingReminder:
            return false
        }
    }

    var currentApprovalActions: [ApprovalAction] {
        if case let .approval(viewModel) = mode {
            return viewModel.actions
        }
        return []
    }

    func showStatus(_ phase: CodexPhase) {
        mode = .collapsed(phase)
        onApprovalSelect = nil
    }

    func showApproval(
        _ viewModel: ApprovalRequestViewModel,
        onSelect: @escaping (ApprovalAction) -> Void
    ) {
        if viewModel.actions.isEmpty {
            mode = .waitingReminder(viewModel)
            onApprovalSelect = nil
        } else {
            mode = .approval(viewModel)
            onApprovalSelect = onSelect
        }
    }

    func selectApprovalAction(_ action: ApprovalAction) {
        guard case .approval = mode else {
            return
        }
        onApprovalSelect?(action)
        showStatus(.working)
    }
}

struct DynamicIslandSurfaceView: View {
    @ObservedObject var store: DynamicIslandSurfaceStore

    @State private var hasAppeared = false

    private var isExpanded: Bool {
        switch store.mode {
        case .approval, .waitingReminder:
            return true
        case .collapsed:
            return false
        }
    }

    private var surfaceSize: CGSize {
        switch store.mode {
        case .collapsed:
            return NotchLayoutMetrics.collapsedSize
        case .waitingReminder:
            return NotchLayoutMetrics.waitingReminderSize
        case .approval:
            return NotchLayoutMetrics.expandedApprovalSize
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            islandSurface
                .frame(width: surfaceSize.width, height: surfaceSize.height, alignment: .top)
                .clipShape(surfaceShape)
                .background {
                    surfaceShape
                        .fill(.black.opacity(0.93))
                        .shadow(color: .black.opacity(isExpanded ? 0.34 : 0.22), radius: isExpanded ? 24 : 12, x: 0, y: isExpanded ? 16 : 6)
                }
                .overlay {
                    surfaceShape
                        .stroke(.white.opacity(isExpanded ? 0.09 : 0.06), lineWidth: 1)
                }
                .scaleEffect(hasAppeared ? 1 : 0.98, anchor: .top)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.spring(response: 0.36, dampingFraction: 0.82), value: store.mode)
                .animation(.easeOut(duration: 0.16), value: hasAppeared)

            Spacer(minLength: 0)
        }
        .frame(width: NotchLayoutMetrics.windowSize.width, height: NotchLayoutMetrics.windowSize.height, alignment: .top)
        .background(.black.opacity(0.001))
        .preferredColorScheme(.dark)
        .onAppear {
            hasAppeared = true
        }
    }

    private var surfaceShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: isExpanded ? 30 : 18, style: .continuous)
    }

    @ViewBuilder
    private var islandSurface: some View {
        VStack(spacing: 0) {
            header
                .frame(height: NotchLayoutMetrics.closedHeaderHeight)

            if let viewModel = approvalViewModel {
                approvalBody(viewModel)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var approvalViewModel: ApprovalRequestViewModel? {
        switch store.mode {
        case .collapsed:
            return nil
        case let .waitingReminder(viewModel), let .approval(viewModel):
            return viewModel
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            statusDot

            Text(headerTitle)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)

            if isExpanded {
                Spacer(minLength: 0)
                Text("等待审批")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.orange.opacity(0.95))
            }
        }
        .padding(.horizontal, isExpanded ? 18 : 13)
    }

    private var statusDot: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.22))
                .frame(width: 18, height: 18)
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .shadow(color: statusColor.opacity(0.9), radius: 5)
        }
    }

    private var headerTitle: String {
        switch store.mode {
        case let .collapsed(phase):
            return shortLabel(for: phase)
        case let .waitingReminder(viewModel):
            return viewModel.projectName
        case let .approval(viewModel):
            return viewModel.projectName
        }
    }

    private var statusColor: Color {
        switch store.mode {
        case let .collapsed(phase):
            return color(for: phase)
        case .waitingReminder, .approval:
            return .orange
        }
    }

    private func approvalBody(_ viewModel: ApprovalRequestViewModel) -> some View {
        VStack(alignment: .leading, spacing: viewModel.actions.isEmpty ? 8 : 12) {
            Text(viewModel.reason ?? "Codex 请求确认本次操作。")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.66))
                .lineLimit(viewModel.actions.isEmpty ? 1 : 2)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.actions.isEmpty {
                Text("请回到 Codex 处理审批。")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange.opacity(0.92))
            } else {
                HStack(spacing: 8) {
                    ForEach(viewModel.actions) { action in
                        approvalButton(action)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, viewModel.actions.isEmpty ? 12 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func approvalButton(_ action: ApprovalAction) -> some View {
        Button {
            store.selectApprovalAction(action)
        } label: {
            VStack(spacing: 1) {
                Text(compactTitle(for: action))
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                if let subtitle = action.subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(subtitleColor(for: action.style))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(foregroundColor(for: action.style))
            .frame(width: 112, height: 42)
            .background {
                Capsule()
                    .fill(backgroundColor(for: action.style))
            }
            .overlay {
                Capsule()
                    .stroke(borderColor(for: action.style), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private func color(for phase: CodexPhase) -> Color {
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

    private func shortLabel(for phase: CodexPhase) -> String {
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

    private func compactTitle(for action: ApprovalAction) -> String {
        switch action.style {
        case .primary:
            return "批准一次"
        case .extended:
            return "会话批准"
        case .destructive:
            return "拒绝"
        }
    }

    private func foregroundColor(for style: ApprovalActionStyle) -> Color {
        switch style {
        case .primary:
            return .black
        case .extended:
            return .white
        case .destructive:
            return .white.opacity(0.72)
        }
    }

    private func subtitleColor(for style: ApprovalActionStyle) -> Color {
        switch style {
        case .primary:
            return .black.opacity(0.62)
        case .extended:
            return .white.opacity(0.58)
        case .destructive:
            return .white.opacity(0.38)
        }
    }

    private func backgroundColor(for style: ApprovalActionStyle) -> Color {
        switch style {
        case .primary:
            return .white.opacity(0.94)
        case .extended:
            return .orange.opacity(0.82)
        case .destructive:
            return .white.opacity(0.10)
        }
    }

    private func borderColor(for style: ApprovalActionStyle) -> Color {
        switch style {
        case .primary:
            return .white.opacity(0.96)
        case .extended:
            return .orange.opacity(0.96)
        case .destructive:
            return .white.opacity(0.08)
        }
    }
}
