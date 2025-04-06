//
//  Storable.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import Foundation

// MARK: - Storable Protocol

public protocol Storable: Hashable, Codable {
    var id: String { get }
    var dateCreated: Date { get }
    var lastUpdated: Date { get set }
    var version: Int { get set }
}
