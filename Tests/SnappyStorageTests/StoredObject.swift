//
//  StoredObject.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-08.
//

import XCTest
@testable import SnappyStorage

struct StoredObject: Storable {
    var id: String
    var key: String
    
    init(key: String) {
        self.id = Self.generateHexID()
        self.key = key
    }
}

extension StoredObject {
    static var value: StoredObject {
        .init(key: "value")
    }

    static var value1: StoredObject {
        .init(key: "value1")
    }

    static var value2: StoredObject {
        .init(key: "value2")
    }
}
