import Foundation

public struct AutomaticThresholds: Equatable, Sendable {

    public var maxDefaultBytes: Int = 256_000
    public var maxDefaultItems: Int = 500

    public static let `default` = AutomaticThresholds()
}
