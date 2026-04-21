import AppKit

@main
enum CodexStatusRadarApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.finishLaunching()
        delegate.start()

        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}
