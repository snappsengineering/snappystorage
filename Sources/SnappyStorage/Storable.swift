//
//  Storable.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

public protocol Storable: Codable, Hashable, Identifiable {
    var id: String { get }
}

extension Storable {
    public static func generateHexID(length: Int = 6) -> String {
        let randomValue = Int.random(in: 0...(16_777_215)) // 16_777_215 is the decimal value of FFFFFF
        return String(format: "%0\(length)X", randomValue)
    }
    
    // Conformance to Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Use the id property to generate the hash
    }
    
    // Conformance to Equatable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
