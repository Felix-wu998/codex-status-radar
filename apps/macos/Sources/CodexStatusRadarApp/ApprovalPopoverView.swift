import CodexStatusRadarCore
import SwiftUI

struct ApprovalPopoverView: View {
    let viewModel: ApprovalRequestViewModel
    let onSelect: (ApprovalAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.projectName)
                    .font(.headline)
                    .lineLimit(1)

                if let reason = viewModel.reason {
                    Text(reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            HStack(spacing: 8) {
                ForEach(viewModel.actions) { action in
                    Button {
                        onSelect(action)
                    } label: {
                        VStack(spacing: 2) {
                            Text(action.title)
                                .font(.callout)
                                .lineLimit(1)
                            if let subtitle = action.subtitle {
                                Text(subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 38)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(tint(for: action.style))
                }
            }
        }
        .padding(14)
        .frame(width: 380, height: 150)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 12)
    }

    private func tint(for style: ApprovalActionStyle) -> Color {
        switch style {
        case .primary:
            return .blue
        case .extended:
            return .orange
        case .destructive:
            return .red
        }
    }
}
