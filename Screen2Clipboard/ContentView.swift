import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var settings: AppSettings
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button {
            settings.isEnabled.toggle()
        } label: {
            Label(
                settings.isEnabled ? "Screenshot Clipboard Enabled" : "Screenshot Clipboard Disabled",
                systemImage: settings.isEnabled ? "checkmark.circle" : "circle"
            )
        }
        .keyboardShortcut("e", modifiers: [.command])

        Divider()

        Button("Open Screenshots Folder") {
            NSWorkspace.shared.open(URL(fileURLWithPath: settings.screenshotFolderPath, isDirectory: true))
        }

        Button("Settings…") {
            openSettings()
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}
