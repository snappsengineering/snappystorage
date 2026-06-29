import Foundation

// MARK: - Storable

public protocol Storable: Codable, Hashable, Identifiable {
    var id: String { get }
}

// MARK: - Default implementations

extension Storable {

    public static func generateHexID(length: Int = 6) -> String {
        let randomValue = Int.random(in: 0...(16_777_215))
        return String(format: "%0\(length)X", randomValue)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension Set where Element: Storable {

    mutating func upsert(_ item: Element) {
        remove(item)
        insert(item)
    }
}
