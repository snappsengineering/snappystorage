//
//  Storable.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

public protocol Storable: Codable, Hashable, Identifiable {
    var id: ObjectID { get }
}

extension Storable {
    // Conformance to Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Use the id property to generate the hash
    }
    
    // Conformance to Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
