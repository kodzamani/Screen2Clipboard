import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Toggle("Enable Screenshot Clipboard", isOn: $settings.isEnabled)
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            HStack {
                Text("Screenshot folder")
                Spacer(minLength: 12)
                Text(settings.screenshotFolderPath.replacingOccurrences(
                    of: FileManager.default.homeDirectoryForCurrentUser.path,
                    with: "~"
                ))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                Button("Choose…", action: chooseFolder)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.directoryURL = URL(fileURLWithPath: settings.screenshotFolderPath)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        settings.setScreenshotFolder(url)
    }
}
