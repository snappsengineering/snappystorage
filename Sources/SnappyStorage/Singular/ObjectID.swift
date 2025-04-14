//
//  ObjectID.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-14.
//

public struct ObjectID: Hashable, Equatable, Codable {
    public var id: String
    
    public init() {
        self.id = ObjectID.makeID()
    }
    
    public static func makeID(with length: Int = 6) -> String {
        let randomValue = Int.random(in: 0...(16_777_215)) // 16_777_215 is the decimal value of FFFFFF
        return String(format: "%0\(length)X", randomValue)
    }
}
