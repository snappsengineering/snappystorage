import Foundation

/// On-disk layout for `Service<T>` collections.
///
/// Display order is handled in the UI; layouts optimize for lookup, partial I/O, and disk use.
/// See `docs/STORAGE_LAYOUT.md` for migration and encryption behavior.
public enum CollectionLayout: Equatable, Sendable {

    /// Single JSON array file (default). Best disk efficiency for small collections.
    case monolith

    /// Split collection across a few chunk files. Balance of partial read/write and disk space.
    case chunked(ChunkPolicy)

    /// One file per record id. Best partial I/O for large payloads; poor for tiny rows.
    case perRecord

    /// Start as monolith; migrate to chunked when thresholds are exceeded.
    case automatic(AutomaticThresholds, fallback: ChunkPolicy = .default)

    /// Sensible defaults for chunked layout.
    public static let defaultChunked = CollectionLayout.chunked(.default)
}

/// Limits for each chunk file in `.chunked` layout.
public struct ChunkPolicy: Equatable, Sendable {
    /// Max items per chunk file.
    public var maxItemsPerChunk: Int
    /// Max encoded JSON bytes per chunk before starting a new chunk.
    public var maxBytesPerChunk: Int

    public init(maxItemsPerChunk: Int = 50, maxBytesPerChunk: Int = 256_000) {
        self.maxItemsPerChunk = maxItemsPerChunk
        self.maxBytesPerChunk = maxBytesPerChunk
    }

    public static let `default` = ChunkPolicy()
}

/// When to migrate from monolith to chunked in `.automatic` layout.
public struct AutomaticThresholds: Equatable, Sendable {
    public var maxMonolithBytes: Int
    public var maxMonolithItems: Int

    public init(maxMonolithBytes: Int = 256_000, maxMonolithItems: Int = 500) {
        self.maxMonolithBytes = maxMonolithBytes
        self.maxMonolithItems = maxMonolithItems
    }

    public static let `default` = AutomaticThresholds()
}

extension CollectionLayout {

    /// UserDefaults / manifest key suffix for persisting layout migration version.
    public static func layoutVersionKey(fileName: String) -> String {
        "SnappyStorage.layoutVersion.\(fileName)"
    }

    /// Whether this layout uses a single file at `fileName.json` (monolith or pre-migration automatic).
    public var usesMonolithFile: Bool {
        switch self {
        case .monolith, .automatic: return true
        case .chunked, .perRecord: return false
        }
    }
}
