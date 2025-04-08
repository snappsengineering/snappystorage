//
//  Storable.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

public protocol Storable: Equatable, Codable, Identifiable {
    var objectID: String { get }
    var attributes: [String: Any] { get set }
}

public extension Storable {
    var id: String {
        objectID
    }

    var objectID: String {
        get { (attributes["objectID"] as? String)! }
        set { attributes["objectID"] = newValue }
    }
}
