//
//  SnappyError.swift
//  SnappyStorage
//
//  Created by Shane Noormohamed on 2024-10-12.
//

// MARK: Errors Enum

enum SnappyError: Error {
    case conversionError
    case fileNotFound
    case keychainError
    case invalidOperationError
    case emptyDataError
    case dataNotFound
}
