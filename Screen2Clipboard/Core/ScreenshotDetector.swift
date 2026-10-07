import Foundation
import UniformTypeIdentifiers

struct ScreenshotDetector {
    private(set) var baseline: Set<FileIdentity> = []
    private(set) var processed: Set<FileIdentity> = []

    mutating func establishBaseline(in directory: URL) {
        baseline = Set((try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileResourceIdentifierKey, .creationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ))?.compactMap(Self.identity(for:)) ?? [])
    }

    mutating func candidates(in directory: URL) -> [URL] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileResourceIdentifierKey, .creationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return files.compactMap { url in
            guard Self.isSupportedImage(url),
                  let values = try? url.resourceValues(forKeys: [.creationDateKey, .isRegularFileKey]),
                  values.isRegularFile == true,
                  let identity = Self.identity(for: url),
                  !baseline.contains(identity),
                  processed.insert(identity).inserted else { return nil }
            return url
        }
    }

    mutating func allowRetry(for url: URL) {
        guard let identity = Self.identity(for: url) else { return }
        processed.remove(identity)
    }

    nonisolated static func isSupportedImage(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension.lowercased()) else { return false }
        return type.conforms(to: .image) && [.png, .jpeg, .heic].contains { type.conforms(to: $0) }
    }

    nonisolated private static func identity(for url: URL) -> FileIdentity? {
        guard let values = try? url.resourceValues(forKeys: [.fileResourceIdentifierKey, .creationDateKey]) else {
            return nil
        }
        return FileIdentity(
            path: url.standardizedFileURL.path,
            resourceIdentifier: values.fileResourceIdentifier.map(String.init(describing:)) ?? "",
            creationDate: values.creationDate
        )
    }
}

struct FileIdentity: Hashable {
    let path: String
    let resourceIdentifier: String
    let creationDate: Date?
}
