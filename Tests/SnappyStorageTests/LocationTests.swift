//
//  LocationTests.swift
//  SnappyStorage
//
//  Created by snapps engineering ltd.
//


import XCTest
@testable import SnappyStorage

final class LocationTests: XCTestCase {
    
    func testLocalURLCreation() {
        let location = Location<StoredObject>(destination: .local(.documentDirectory))
        XCTAssertNotNil(location.url)
    }
}
