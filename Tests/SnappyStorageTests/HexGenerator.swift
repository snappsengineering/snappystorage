//
//  HexGenerator.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-08.
//


struct HexGenerator {
    /// Generates a random 6-digit hexadecimal string
    static func generateHexID() -> String {
        let randomValue = Int.random(in: 0...(16_777_215)) // 16_777_215 is the decimal value of FFFFFF
        return String(format: "%06X", randomValue)
    }
}