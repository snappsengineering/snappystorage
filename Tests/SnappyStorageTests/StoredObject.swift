//
//  StoredObject.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-08.
//

import XCTest
@testable import SnappyStorage

struct StoredObject: Storable {
    
    static func == (lhs: StoredObject, rhs: StoredObject) -> Bool {
        lhs.objectID == rhs.objectID
    }
    
    var id: String {
        objectID
    }
    
    var attributes: [String: Any] = [:]
    
    init(objectID: String = HexGenerator.generateHexID(), key: String) {
        self.objectID = objectID
        self.key = key
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let data = try values.decode(Data.self, forKey: .attributes)
        attributes = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
    
    enum CodingKeys: String, CodingKey {
        case attributes
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let data = try JSONSerialization.data(withJSONObject: attributes, options: [])
        try container.encode(data, forKey: .attributes)
    }
    
    var objectID: String {
        get { (attributes["objectID"] as? String)! }
        set { attributes["objectID"] = newValue }
    }
    
    var key: String {
        get { (attributes["key"] as? String)! }
        set { attributes["key"] = newValue }
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
