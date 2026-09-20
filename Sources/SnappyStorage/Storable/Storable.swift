import Foundation

// MARK: - Storable

public protocol Storable: Codable, Hashable, Identifiable {
    var id: String { get }
}

// MARK: - Default implementations

extension Storable {

    public static func generateHexID(length: Int = 6) -> String {
        let digits = "0123456789ABCDEF"
        return String((0..<length).map { _ in digits.randomElement()! })
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
