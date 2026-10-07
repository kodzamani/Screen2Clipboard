import AppKit
import XCTest
@testable import Screen2Clipboard

final class ScreenshotClipboardTests: XCTestCase {
    func testDetectorIgnoresBaselineAndAcceptsNewLocalizedScreenshotOnce() throws {
        let directory = try makeTemporaryDirectory()
        let oldFile = directory.appending(path: "old.png")
        try Data([1]).write(to: oldFile)
        var detector = ScreenshotDetector()
        detector.establishBaseline(in: directory)
        XCTAssertTrue(detector.candidates(in: directory).isEmpty)

        let newFile = directory.appending(path: "Ekran Resmi 2026-10-07 at 14.30.12.png")
        try Data([1]).write(to: newFile)
        XCTAssertEqual(detector.candidates(in: directory).map(\.standardizedFileURL), [newFile.standardizedFileURL])
        XCTAssertTrue(detector.candidates(in: directory).isEmpty)
    }

    func testDetectorIgnoresUnsupportedFiles() throws {
        let directory = try makeTemporaryDirectory()
        var detector = ScreenshotDetector()
        detector.establishBaseline(in: directory)
        for name in ["document.pdf", "notes.txt", "photo.gif"] {
            try Data([1]).write(to: directory.appending(path: name))
        }
        XCTAssertTrue(detector.candidates(in: directory).isEmpty)
    }

    func testSupportedImageExtensions() {
        for name in ["capture.png", "capture.jpg", "capture.jpeg", "capture.heic"] {
            XCTAssertTrue(ScreenshotDetector.isSupportedImage(URL(fileURLWithPath: name)))
        }
        XCTAssertFalse(ScreenshotDetector.isSupportedImage(URL(fileURLWithPath: "capture.gif")))
    }

    func testFileReadyCheckerAcceptsStableFileAndRejectsMissingFile() async throws {
        let directory = try makeTemporaryDirectory()
        let file = directory.appending(path: "capture.png")
        try Data([1, 2, 3]).write(to: file)
        let checker = FileReadyChecker(interval: .milliseconds(5), attempts: 3)
        let ready = await checker.waitUntilReady(file)
        let missing = await checker.waitUntilReady(directory.appending(path: "missing.png"))
        XCTAssertTrue(ready)
        XCTAssertFalse(missing)
    }

    @MainActor
    func testClipboardContainsPNGAndTIFF() throws {
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 2,
            pixelsHigh: 2,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        bitmap.setColor(.red, atX: 0, y: 0)
        let image = NSImage(size: NSSize(width: 2, height: 2))
        image.addRepresentation(bitmap)
        let manager = ClipboardManager()
        XCTAssertTrue(manager.copyImage(image))
        XCTAssertNotNil(NSPasteboard.general.data(forType: .png))
        XCTAssertNotNil(NSPasteboard.general.data(forType: .tiff))
    }

    @MainActor
    func testInvalidImageDoesNotOverwriteClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("preserve", forType: .string)
        let manager = ClipboardManager()
        XCTAssertFalse(manager.copyImage(NSImage(size: .zero)))
        XCTAssertEqual(pasteboard.string(forType: .string), "preserve")
    }

    @MainActor
    func testSettingsPersistEnabledStateAndScreenshotFolder() throws {
        let suite = "ScreenshotClipboardTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        let directory = try makeTemporaryDirectory()
        settings.setScreenshotFolder(directory)
        settings.isEnabled = false
        XCTAssertEqual(defaults.string(forKey: "screenshotFolderPath"), directory.path)
        XCTAssertFalse(defaults.bool(forKey: "isEnabled"))
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
