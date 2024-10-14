//
//  Storable.swift
//  retoxifier (iOS)
//
//  Created by Shane Noormohamed on 12/22/23.
//

import Foundation

// MARK: - Storable Protocol

public protocol Storable: Equatable, Codable {
    var objectID: String { get }
    var updatedAt: Date { get }
}

// MARK: - SavedEntity Struct

public struct SavedEntity: Storable  {
    
    // MARK: Private properties
    
    public var objectID: String
    public var updatedAt: Date
    
    // MARK: init
    
    init() {
        objectID = UUID().uuidString
        updatedAt = Date()
    }
}
