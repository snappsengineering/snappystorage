//
//  Destination.swift
//  SnappyStorage
//
//  Created by snapps engineering ltd.
//

import Foundation

// MARK: Enums

public enum Destination<T: Storable> {
    case local(FileManager.SearchPathDirectory)
    case cloud
    case custom(String)
    
    static var documentsFolderName: String {
        "Documents"
    }
    
    var fileName: String {
        "\(T.self).json"
    }
    
    func makeURL(with fileManager: FileManager) -> URL? {
        let result: URL?
        switch self {
        case .local(let directory):
            result = fileManager.urls(for: directory, in: .userDomainMask).last
        case .cloud:
            result = fileManager.url(forUbiquityContainerIdentifier: nil)?
                .appendingPathComponent(Destination.documentsFolderName)
        case .custom(let path):
            result = URL(string: path)?.appendingPathComponent(fileName)
        }
        return result?.appendingPathComponent(fileName)
    }
}
