import AppKit
import os

@MainActor
protocol ClipboardManaging {
    func copyImage(_ image: NSImage) -> Bool
}

@MainActor
final class ClipboardManager: ClipboardManaging {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Screen2Clipboard", category: "ClipboardManager")

    func copyImage(_ image: NSImage) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            logger.error("Could not create image representations for clipboard")
            return false
        }

        let item = NSPasteboardItem()
        guard item.setData(pngData, forType: .png),
              item.setData(tiffData, forType: .tiff) else {
            logger.error("Could not prepare pasteboard image item")
            return false
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.writeObjects([item]) else {
            logger.error("Could not write screenshot to pasteboard")
            return false
        }
        return true
    }
}
