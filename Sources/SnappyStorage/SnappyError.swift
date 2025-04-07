//
//  SnappyError.swift
//  SnappyStorage
//
//  Created by Shane on 2025-04-07.
//


//
//  SnappyError.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

// MARK: Errors Enum

public enum SnappyError: Error {
    case invalidOperationError(String)
    case decodingError(String)
}
