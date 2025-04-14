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

public enum RelationshipType<T: Storable, U: Storable> {
    case oneToOne(T.ID, U.ID)
    case oneToMany(T.ID, [U.ID])
    case manyToMany([T.ID], [U.ID])
}
