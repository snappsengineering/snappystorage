import Foundation

// Codable (not Storable) — SingleValueService manages one instance of this type,
// stored as a single JSON file rather than a keyed collection.
struct UserPreferences: Codable {
    var displayName: String = ""
    var notificationsEnabled: Bool = true
    var accentColorName: String = "blue"
}
