//
//  Storable.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

public protocol Storable: ObservableObject, Equatable, Codable {
    var attributes: [String: Any] { get set }
}

open class StoredObject: Storable  {
    public var attributes: [String : Any] = [:]
    
    public init() {
        objectID = UUID().uuidString
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let data = try values.decode(Data.self, forKey: .attributes)
        attributes = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
    
    enum CodingKeys: String, CodingKey {
        case attributes
    }

    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let data = try JSONSerialization.data(withJSONObject: attributes, options: [])
        try container.encode(data, forKey: .attributes)
    }
}

extension StoredObject: Equatable {
    public static func == (lhs: StoredObject, rhs: StoredObject) -> Bool{
        return lhs.objectID == rhs.objectID
    }
}

extension StoredObject {
    public var objectID: String {
        get { (attributes[.objectID] as? String)! }
        set { attributes[.objectID] = newValue }
    }
}

private extension String {
    static let objectID = "objectID"
}
