import Foundation

/// Answers whether a file or folder is still at a given location.
@MainActor
public protocol FileExistenceChecking: AnyObject {
    func fileExists(at url: URL) -> Bool
}
