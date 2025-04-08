//
//  Location.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-08.
//

import Foundation

struct Location<T: Storable> {
    
    let fileManager: FileManager
    let destination: Destination
    
    private let fileName: String  = "\(T.self).json"
    
    var url: URL?
    
    init(
        fileManager: FileManager = .default,
        destination: Destination
    ) {
        self.fileManager = fileManager
        self.destination = destination
        
        self.url = makeURL()
    }
    
    var fileExists: Bool {
        guard let path = url?.path else { return false }
        return fileManager.fileExists(atPath: path)
    }
    
    func makeURL() -> URL? {
        let result: URL?
        switch destination {
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
