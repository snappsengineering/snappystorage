//
//  Storable.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

public protocol Storable: Equatable, Codable, Identifiable {
    var id: String { get }
}

extension Storable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
