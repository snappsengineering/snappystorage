//
//  TestStorage.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-06.
//

import XCTest
@testable import SnappyStorage

class TestStorage<T: Storable>: Storage<T> {
    override func getFilePath() -> URL? {
        let fileManager = FileManager.default
        let storeURL = try? fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let errorURL = storeURL?.appendingPathComponent("ErrorDirectory")
        return errorURL
    }
}
