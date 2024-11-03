//
//  Storable.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import Foundation

// MARK: - Storable Protocol

public protocol Storable: Equatable, Codable {
    var objectID: String { get }
}

// MARK: - Extension

extension Storable  {
    var objectID: String {
        UUID().uuidString
    }
}
