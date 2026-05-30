import Foundation

public protocol Storable: Codable, Equatable, Identifiable {
    var id: String { get }
}

extension Storable {
    public static func generateHexID(length: Int = 6) -> String {
        let randomValue = Int.random(in: 0...(16_777_215))
        return String(format: "%0\(length)X", randomValue)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
