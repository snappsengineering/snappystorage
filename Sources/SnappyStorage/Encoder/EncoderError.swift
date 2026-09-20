import Foundation

public enum EncoderError: LocalizedError {

    // MARK: - Cases

    case encodingFailed(Error)
    case decodingFailed(Error)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let error): return "Encoding failed: \(error.localizedDescription)"
        case .decodingFailed(let error): return "Decoding failed: \(error.localizedDescription)"
        }
    }
}
