//
//  Storable.swift
//  snappystorage
//
//  Created by snapps engineering ltd.
//

import Foundation

public protocol Storable: Equatable, Codable, Identifiable {
    var objectID: String { get }
    var attributes: [String: Any] { get set }
}
