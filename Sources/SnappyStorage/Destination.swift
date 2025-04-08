//
//  Destination.swift
//  SnappyStorage
//
//  Created by snapps engineering ltd.
//

import Foundation

// MARK: Enums

enum Destination {
    case local(FileManager.SearchPathDirectory)
    case cloud
    case custom(String)
    
    static var documentsFolderName: String {
        "Documents"
    }
}
