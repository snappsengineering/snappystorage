//
//  Location.swift
//  SnappyStorage
//
//  Created by Shane Noormohamed on 2024-10-13.
//

import Foundation

struct Location<T: Storable> {

    enum Destination {
        case local
        case cloud
    }

    private let fileManager: FileManager
    private let destination: Destination
    
    lazy var url: URL? = {
       makeURL(for: destination)
    }()
    
    // MARK: File Paths
    
    private let fileName: String = Folder.file.rawValue
    
    private func makeURL(for destination: Destination) -> URL? {
        var locationURL: URL?

        switch destination {
        case .local:
            guard let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).last else { return nil }
            locationURL = directoryURL
        case .cloud:
            guard let cloudURL = fileManager.url(forUbiquityContainerIdentifier: nil) else { return nil }
            let documentsURL = cloudURL.appendingPathComponent(Folder.documents.rawValue)
            locationURL = documentsURL
        }
        
        let fileURL = locationURL?.appendingPathComponent(fileName)
        return fileURL
    }
    
    enum Folder {
        case documents
        case file

        var rawValue: String {
            switch self {
            case .documents: return "Documents"
            case .file: return "\(T.self).json"
            }
        }
    }
}
