//
//  ObjectID.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-14.
//

public struct ObjectID: Hashable, Equatable, Codable {
    public var id: String
    
    public static func make() -> ObjectID {
        let randomValue = Int.random(in: 0...(16_777_215)) // 16_777_215 is the decimal value of FFFFFF
        return ObjectID(id: String(format: "%0\(6)X", randomValue))
    }
}
