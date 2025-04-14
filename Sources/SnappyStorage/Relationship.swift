//
//  Relationship.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-14.
//

import Foundation

public protocol Relationship<T, U>: Storable {
    associatedtype T: Storable
    associatedtype U: Storable
    
    var type: RelationshipType<T, U> { get }
}

public enum RelationshipType<T: Storable, U: Storable>: Codable {
    case oneToOne(tID: ObjectID, uID: ObjectID)
    case oneToMany(tID: ObjectID, uIDs: [ObjectID])
    case manyToMany(tIDs: [ObjectID], uIDs: [ObjectID])
}
