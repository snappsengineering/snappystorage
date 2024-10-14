//
//  Storable.swift
//  retoxifier (iOS)
//
//  Created by Shane Noormohamed on 12/22/23.
//

import Foundation

protocol Storable: Equatable, Codable {
    var attributes: [String: Any] { get set }
}

class StoredObject: Storable  {
    var attributes: [String : Any] = [:]
    
    init() {
        objectID = UUID().uuidString
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let data = try values.decode(Data.self, forKey: .attributes)
        attributes = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
}

extension StoredObject: Encodable {
    enum CodingKeys: String, CodingKey {
        case attributes
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let data = try JSONSerialization.data(withJSONObject: attributes, options: [])
        try container.encode(data, forKey: .attributes)
    }
}

extension StoredObject: Equatable {
    static func == (lhs: StoredObject, rhs: StoredObject) -> Bool{
        return lhs.objectID == rhs.objectID && lhs.updatedAt == rhs.updatedAt
    }
}

extension StoredObject {
    var objectID: String {
        get { (attributes[.objectID] as? String)! }
        set { attributes[.objectID] = newValue }
    }
    
    var updatedAt: Date {
        get { (attributes[.updatedAt] as? Date)! }
        set { attributes[.updatedAt] = newValue }
    }
}

private extension String {
    static let objectID = "objectID"
    static let updatedAt = "updatedAt"
}
