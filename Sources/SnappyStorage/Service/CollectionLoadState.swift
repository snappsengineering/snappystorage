import Foundation

/// Where the in-memory collection stands relative to the on-disk file.
public enum CollectionLoadState: Sendable, Equatable {
    case notLoaded
    case loaded(count: Int)
    case empty
    case failed
}

/// Thrown when a write is refused because the on-disk file could not be read.
public enum ServiceError: Error, Sendable, Equatable {
    case persistBlockedByLoadFailure
}

/// Tuning for lazy load and coalesced disk writes.
public struct ServiceConfiguration: Sendable {
    /// When non-nil and positive, `save`/`delete` schedule a single persist after this interval;
    /// call `flush()` to persist immediately.
    public var persistCoalesceInterval: TimeInterval?

    public init(persistCoalesceInterval: TimeInterval? = nil) {
        self.persistCoalesceInterval = persistCoalesceInterval
    }
}
