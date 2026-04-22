import CoreGraphics

enum NotchLayoutMetrics {
    static let collapsedSize = CGSize(width: 128, height: 36)
    static let waitingReminderSize = CGSize(width: 420, height: 112)
    static let expandedApprovalSize = CGSize(width: 620, height: 148)
    static let windowSize = CGSize(width: 660, height: 174)
    static let closedHeaderHeight = collapsedSize.height

    static let statusSize = collapsedSize
    static let approvalSize = expandedApprovalSize
}
