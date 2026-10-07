# Screen2Clipboard

A small, native macOS menu bar utility that copies new screenshots to the clipboard automatically. Take a screenshot with the built-in macOS shortcuts, then paste the image with `⌘V`.

## Features

- Watches a configurable screenshot folder using filesystem events.
- Ignores files already present when monitoring starts.
- Supports PNG, JPG/JPEG, and HEIC images, independent of localized screenshot filenames.
- Waits for a screenshot file to stabilize before loading it.
- Places actual image data (PNG and TIFF) on the clipboard; it does not copy a file URL.
- Provides a menu bar enable/disable control and settings for the watched folder and launch at login.
- Runs without a Dock icon or a regular app window.
- Works locally; no account, network service, analytics, or success notifications.

## Requirements

- macOS 14.6 or later (the current Xcode project deployment target)
- Xcode 14.6 or later to build the project

## Build and run

1. Open `Screen2Clipboard.xcodeproj` in Xcode.
2. Select the `Screen2Clipboard` scheme and run the app.
3. Find the camera icon in the menu bar. The app starts enabled and watches `~/Desktop` by default.
4. Take a screenshot using a standard macOS shortcut, then paste it into another app with `⌘V`.

To change the folder or launch-at-login behavior, open the menu bar item and choose **Settings…**. Use **Choose…** to select a different screenshot folder. Disable monitoring from the menu item’s enabled-state toggle.

## Permissions and privacy

The app does not request Screen Recording, Accessibility, or Full Disk Access. The target is not App Sandbox enabled so it can watch the default Desktop folder directly; macOS privacy controls may still require the user to allow access. Folder access failures are logged and do not display notifications by default.

The selected folder path and preferences are stored locally in standard app preferences. Screenshot images are not uploaded or retained by the app. The app only reads new supported image files in the monitored folder to copy their image data to the clipboard.

## Tests

Run the unit tests from Terminal:

```sh
xcodebuild test \
  -project Screen2Clipboard.xcodeproj \
  -scheme Screen2Clipboard \
  -destination 'platform=macOS'
```

The tests cover screenshot discovery and duplicate suppression, supported formats, file readiness, clipboard image representations and failure handling, and persisted settings.

## Launch at login

The setting uses Apple’s `SMAppService` API. macOS may require confirmation or may restrict login-item registration depending on how the app was built and launched. For normal distribution, archive and sign the app with your Developer ID before sharing it.

## Project structure

```text
Screen2Clipboard/
├── Core/       # Filesystem monitoring, detection, readiness, clipboard
├── Models/     # Persisted app settings
├── Services/   # Launch-at-login integration
└── UI/         # Menu bar and settings views
```

## License

No license has been selected yet. Add a `LICENSE` file before publishing if you want to grant others permission to use, modify, and redistribute this project.
