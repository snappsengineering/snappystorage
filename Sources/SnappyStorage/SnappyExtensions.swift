//
//  SnappyExtensions.swift
//  SnappyStorage
//
//  Created by Shane Noormohamed on 2024-10-12.
//

import Foundation

// MARK: - Data Extensions

extension Data {
    var stringValue: String {
        get throws {
            guard let string = String(data: self, encoding: .utf8) else {
                throw SnappyError.conversionError
            }
            return string
        }
    }
}

// MARK: - String Extensions

extension String {
    var dataValue: Data {
        get throws {
            guard let data = self.data(using: .utf8) else {
                throw SnappyError.conversionError
            }
            return data
        }
    }
}

// MARK: - Date Extensions

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    var isInFuture: Bool {
        self.startOfDay >= Date().startOfDay
    }
    
    static var today: Date {
        Date().startOfDay
    }
}
