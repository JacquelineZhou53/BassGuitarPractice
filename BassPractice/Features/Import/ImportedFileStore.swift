import Foundation

/// Copies imported score files into the app's private Application Support
/// directory and resolves the relative paths stored in SwiftData.
enum ImportedFileStore {
    private static let directoryName = "ImportedScores"

    static var directoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(directoryName, isDirectory: true)
    }

    static func ensureDirectory() throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
    }

    /// Copies a security-scoped file into the app and returns its relative
    /// filename. The caller is responsible for starting/stopping access.
    static func copyImportedFile(from url: URL) throws -> String {
        try ensureDirectory()

        let ext = url.pathExtension.lowercased()
        let fileName = UUID().uuidString + (ext.isEmpty ? "" : ".\(ext)")
        let destination = directoryURL.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: url, to: destination)
        return fileName
    }

    static func url(forRelativePath relativePath: String) -> URL {
        directoryURL.appendingPathComponent(relativePath)
    }

    static func delete(relativePath: String) {
        guard !relativePath.isEmpty else { return }
        let url = url(forRelativePath: relativePath)
        guard url.standardizedFileURL.path.hasPrefix(directoryURL.standardizedFileURL.path) else {
            return
        }
        try? FileManager.default.removeItem(at: url)
    }
}
