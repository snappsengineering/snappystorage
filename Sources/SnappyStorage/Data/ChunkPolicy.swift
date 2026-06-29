import Foundation

public struct ChunkPolicy: Equatable, Sendable {

    public var maxItemsPerChunk: Int = 50
    public var maxBytesPerChunk: Int = 256_000

    public static let `default` = ChunkPolicy()
}
