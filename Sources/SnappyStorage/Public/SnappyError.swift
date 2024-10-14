//
//  SnappyError.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

// MARK: Errors Enum

public enum SnappyError: Error {
    case conversionError
    case fileNotFound
    case keychainError
    case invalidOperationError
    case emptyDataError
    case dataNotFound
}
