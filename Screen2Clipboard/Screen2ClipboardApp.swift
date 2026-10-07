import SwiftUI

@main
struct Screen2ClipboardApp: App {
    @StateObject private var settings: AppSettings
    private let monitor: ScreenshotMonitor

    init() {
        let settings = AppSettings()
        let monitor = ScreenshotMonitor(clipboard: ClipboardManager())
        self._settings = StateObject(wrappedValue: settings)
        self.monitor = monitor
        settings.configure(monitor: monitor)
    }

    var body: some Scene {
        MenuBarExtra("Screenshot Clipboard", systemImage: "camera.viewfinder") {
            ContentView(settings: settings)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(settings: settings)
        }
    }
}
