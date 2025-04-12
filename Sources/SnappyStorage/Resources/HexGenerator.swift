//
//  HexGenerator.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-08.
//


public struct HexGenerator {
    /// Generates a random 6-digit hexadecimal string
    public static func generateHexID(length: Int = 6) -> String {
        let randomValue = Int.random(in: 0...(16_777_215)) // 16_777_215 is the decimal value of FFFFFF
        return String(format: "%0\(length)X", randomValue)
    }
}
