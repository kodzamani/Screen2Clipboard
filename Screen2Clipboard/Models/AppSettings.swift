import Combine
import Foundation

@MainActor
final class AppSettings: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Key.isEnabled)
            updateMonitoring()
        }
    }

    @Published var screenshotFolderPath: String {
        didSet {
            defaults.set(screenshotFolderPath, forKey: Key.screenshotFolderPath)
            updateMonitoring()
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Key.launchAtLogin)
            LaunchAtLoginService.setEnabled(launchAtLogin)
        }
    }

    private let defaults: UserDefaults
    private var monitor: ScreenshotMonitoring?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.object(forKey: Key.isEnabled) as? Bool ?? true
        screenshotFolderPath = defaults.string(forKey: Key.screenshotFolderPath)
            ?? FileManager.default.homeDirectoryForCurrentUser.appending(path: "Desktop").path
        launchAtLogin = LaunchAtLoginService.isEnabled
    }

    func configure(monitor: ScreenshotMonitoring) {
        self.monitor = monitor
        updateMonitoring()
    }

    func setScreenshotFolder(_ url: URL) {
        screenshotFolderPath = url.standardizedFileURL.path
    }

    private func updateMonitoring() {
        guard let monitor else { return }
        monitor.stop()
        guard isEnabled else { return }
        monitor.start(at: URL(fileURLWithPath: screenshotFolderPath, isDirectory: true))
    }

    private enum Key {
        static let isEnabled = "isEnabled"
        static let screenshotFolderPath = "screenshotFolderPath"
        static let launchAtLogin = "launchAtLogin"
    }
}
