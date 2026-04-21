import Foundation

public enum PrivacyRedactor {
    public static func projectName(fromPath path: String?) -> String {
        guard let path, !path.isEmpty else {
            return "Unknown Project"
        }

        return URL(fileURLWithPath: path).lastPathComponent
    }

    public static func telemetryPathBucket(fromPath path: String?) -> String {
        guard path != nil else {
            return "unknown"
        }

        return "local-project"
    }
}
