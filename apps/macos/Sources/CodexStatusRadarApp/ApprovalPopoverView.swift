import CodexStatusRadarCore
import SwiftUI

struct ApprovalPopoverView: View {
    let viewModel: ApprovalRequestViewModel
    let onSelect: (ApprovalAction) -> Void

    @State private var hasAppeared = false

    var body: some View {
        HStack(spacing: 14) {
            statusCluster

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(viewModel.projectName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("等待审批")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.orange.opacity(0.95))
                }

                Text(viewModel.reason ?? "Codex 请求确认本次操作。")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
            }
            .frame(maxWidth: 230, alignment: .leading)

            HStack(spacing: 8) {
                ForEach(Array(viewModel.actions.enumerated()), id: \.element.id) { index, action in
                    approvalButton(action)
                        .opacity(hasAppeared ? 1 : 0)
                        .scaleEffect(hasAppeared ? 1 : 0.82)
                        .animation(
                            .spring(response: 0.28, dampingFraction: 0.74).delay(Double(index) * 0.045),
                            value: hasAppeared
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(width: NotchLayoutMetrics.approvalSize.width, height: NotchLayoutMetrics.approvalSize.height)
        .background {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.black.opacity(0.92))
                .shadow(color: .black.opacity(0.32), radius: 24, x: 0, y: 16)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
        .scaleEffect(hasAppeared ? 1 : 0.96, anchor: .top)
        .opacity(hasAppeared ? 1 : 0)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: hasAppeared)
        .onAppear {
            hasAppeared = true
        }
    }

    private var statusCluster: some View {
        ZStack {
            Circle()
                .fill(.orange.opacity(0.18))
                .frame(width: 40, height: 40)
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.orange)
        }
    }

    private func approvalButton(_ action: ApprovalAction) -> some View {
        Button {
            onSelect(action)
        } label: {
            VStack(spacing: 1) {
                Text(compactTitle(for: action))
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)

                if let subtitle = action.subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(subtitleColor(for: action.style))
                }
            }
            .foregroundStyle(foregroundColor(for: action.style))
            .padding(.horizontal, 12)
            .frame(width: 92, height: 42)
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
