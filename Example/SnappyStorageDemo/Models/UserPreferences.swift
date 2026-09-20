import Foundation

struct UserPreferences: Codable {

    // MARK: - Properties

    var displayName: String = ""
    var notificationsEnabled: Bool = true
    var accentColorName: String = "blue"
}
