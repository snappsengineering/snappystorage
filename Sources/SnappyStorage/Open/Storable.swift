//
//  Storable.swift
//  retoxifier (iOS)
//
//  Created by Shane Noormohamed on 12/22/23.
//

import Foundation

// MARK: - Protocol

public protocol Storable: Equatable, Codable {
    var attributes: [String: Any] { get set }
}

open class StoredObject: Storable  {
    
    // MARK: Public properties
    
    public var attributes: [String : Any] = [:]
    
    // MARK: init
    
    init() {
        objectID = UUID().uuidString
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let data = try values.decode(Data.self, forKey: .attributes)
        attributes = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
    }
}

// MARK: - Encodable

extension StoredObject: Encodable {
    enum CodingKeys: String, CodingKey {
        case attributes
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let data = try JSONSerialization.data(withJSONObject: attributes, options: [])
        try container.encode(data, forKey: .attributes)
    }
}

// MARK: - Equatable

extension StoredObject: Equatable {
    public static func == (lhs: StoredObject, rhs: StoredObject) -> Bool{
        return lhs.objectID == rhs.objectID && lhs.updatedAt == rhs.updatedAt
    }
}

// MARK: - Attributes

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

// MARK: - String Extension

private extension String {
    static let objectID = "objectID"
    static let updatedAt = "updatedAt"
}
