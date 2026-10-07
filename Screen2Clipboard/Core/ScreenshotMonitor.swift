import AppKit
import Dispatch
import Foundation
import os

protocol ScreenshotMonitoring: AnyObject {
    func start(at directory: URL)
    func stop()
}

@MainActor
final class ScreenshotMonitor: ScreenshotMonitoring {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Screen2Clipboard", category: "ScreenshotDetector")
    private let queue = DispatchQueue(label: "app.Screen2Clipboard.screenshot-monitor", qos: .utility)
    private let fileReadyChecker = FileReadyChecker()
    private let clipboard: ClipboardManaging
    private var directorySource: DispatchSourceFileSystemObject?
    private var generation = UUID()
    private var detector = ScreenshotDetector()
    private var pendingURLs: [URL] = []
    private var isProcessing = false

    init(clipboard: ClipboardManaging) {
        self.clipboard = clipboard
    }

    func start(at directory: URL) {
        stop()
        let generation = UUID()
        self.generation = generation
        var detector = ScreenshotDetector()
        detector.establishBaseline(in: directory)
        self.detector = detector

        let descriptor = open(directory.path, O_EVTONLY)
        guard descriptor >= 0 else {
            logger.error("Could not monitor screenshot folder: \(directory.path, privacy: .private)")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                self.scan(directory, generation: generation)
            }
        }
        source.setCancelHandler { close(descriptor) }
        directorySource = source
        source.resume()
        scan(directory, generation: generation)
    }

    func stop() {
        generation = UUID()
        directorySource?.cancel()
        directorySource = nil
        pendingURLs.removeAll()
        isProcessing = false
    }

    deinit {
        directorySource?.cancel()
    }

    private func scan(_ directory: URL, generation: UUID) {
        guard self.generation == generation else { return }
        pendingURLs.append(contentsOf: detector.candidates(in: directory))
        processNext(generation: generation)
    }

    private func processNext(generation: UUID) {
        guard !isProcessing, !pendingURLs.isEmpty else { return }
        isProcessing = true
        let url = pendingURLs.removeFirst()
        Task { [weak self, fileReadyChecker] in
            let isReady = await fileReadyChecker.waitUntilReady(url)
            let image = isReady ? await Task.detached(priority: .utility) { NSImage(contentsOf: url) }.value : nil
            guard let self, self.generation == generation else { return }
            if let image, self.clipboard.copyImage(image) {
                self.logger.debug("Copied screenshot to clipboard")
            } else {
                self.detector.allowRetry(for: url)
                self.logger.debug("Screenshot will be retried when the folder changes")
            }
            self.isProcessing = false
            self.processNext(generation: generation)
        }
    }
}
