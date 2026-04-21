import SwiftUI

@main
struct CodexStatusRadarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            Text("Codex Status Radar")
                .frame(width: 320, height: 160)
        }
    }
}
