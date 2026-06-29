import Foundation

public typealias CollectionLayout = Layout

public enum Layout: Equatable, Sendable {
    case `default`
    case chunked(ChunkPolicy)
    case perRecord
    case automatic(AutomaticThresholds, fallback: ChunkPolicy = .default)

    public static let defaultChunked = Layout.chunked(.default)
}

extension Layout {

    static func layoutVersionKey(fileName: String) -> String {
        "SnappyStorage.layoutVersion.\(fileName)"
    }

    var usesDefaultFile: Bool {
        switch self {
        case .default, .automatic: return true
        case .chunked, .perRecord: return false
        }
    }
}
