//
//  StoredRelationship.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-14.
//

import XCTest
@testable import SnappyStorage

struct StoredRelationship: Relationship {
    var id: ObjectID
    var type: RelationshipType<Card, Credential>
    
    init(card: Card, credentials: [Credential]) {
        self.id = card.id
        let credentialIDs = credentials.map { $0.id }
        self.type = .oneToMany(
            tID: card.id,
            uIDs: credentialIDs
        )
    }
}

struct Card: Storable {
    var id: ObjectID
    var name: String
    var userName: String
    var dateCreated: Date = Date()
}

struct Credential: Storable {
    var id: ObjectID
    var value: String
}
