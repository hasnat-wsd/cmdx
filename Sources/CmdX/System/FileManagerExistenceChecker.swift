import CmdXCore
import Foundation

/// Production `FileExistenceChecking` backed by `FileManager`.
@MainActor
final class FileManagerExistenceChecker: FileExistenceChecking {
    func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}
