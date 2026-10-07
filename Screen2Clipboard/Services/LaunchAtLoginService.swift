import Foundation
import ServiceManagement
import os

enum LaunchAtLoginService {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Screen2Clipboard", category: "Settings")

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            logger.error("Could not update launch at login: \(error.localizedDescription, privacy: .public)")
        }
    }
}
