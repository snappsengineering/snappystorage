import Foundation

extension Storage {

    /// Copies the current file to `<name>.<ext>.<suffix>` beside the original; no-op if missing.
    @discardableResult
    func createBackup(suffix: String = "bak") throws -> URL? {
        let source = try location.fileURL()
        guard FileManager.default.exists(at: source) else { return nil }
        let backupURL = try backupURL(suffix: suffix)
        if FileManager.default.exists(at: backupURL) {
            try FileManager.default.removeItem(at: backupURL)
        }
        try FileManager.default.copyItem(at: source, to: backupURL)
        return backupURL
    }

    func backupURL(suffix: String) throws -> URL {
        let source = try location.fileURL()
        return source
            .deletingPathExtension()
            .appendingPathExtension(source.pathExtension + "." + suffix)
    }
}
