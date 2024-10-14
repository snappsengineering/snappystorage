//
//  Storable.swift
//  retoxifier (iOS)
//
//  Created by Shane Noormohamed on 12/22/23.
//

import Foundation

// MARK: - Storable Protocol

public protocol Storable: Equatable, Codable {
    var objectID: String { get }
}

// MARK: - Extension

    var objectID: String {
        UUID().uuidString
    }
}
