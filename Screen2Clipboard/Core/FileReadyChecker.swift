import Foundation

struct FileReadyChecker: Sendable {
    var interval: Duration = .milliseconds(120)
    var attempts: Int = 8

    func waitUntilReady(_ url: URL) async -> Bool {
        var previousSize: Int64?

        for _ in 0..<attempts {
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let fileSize = values.fileSize,
                  fileSize > 0 else {
                try? await Task.sleep(for: interval)
                continue
            }

            let size = Int64(fileSize)
            if size == previousSize { return true }
            previousSize = size
            try? await Task.sleep(for: interval)
        }

        return false
    }
}
