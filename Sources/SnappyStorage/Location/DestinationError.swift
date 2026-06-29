import Foundation

public enum DestinationError: LocalizedError {

    // MARK: - Cases

    case urlNotFound(String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .urlNotFound(let detail): return "Destination URL not found: \(detail)"
        }
    }

    // MARK: - Helpers

    static func requiredURL(_ url: URL?, detail: String) throws -> URL {
        guard let url else { throw urlNotFound(detail) }
        return url
    }
}
