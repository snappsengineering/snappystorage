//
//  BackupPolicy.swift
//
//  Created by Shane Noormohamed.
//  Copyright © 2024 snapps engineering ltd. All rights reserved.
//

import Foundation

public struct BackupPolicy {
    
    // MARK: Private properties
    
    private let calendar: Calendar = .current
    
    // MARK: Internal properties

    internal var frequency: Frequency
    
    // MARK: init
    
    public init(frequency: Frequency) {
        self.frequency = frequency
    }
    
    // MARK: Internal functions
    
    internal func shouldBackup(lastBackup: Date) -> Bool {
        guard frequency != .never else { return false }
        return nextBackup(lastBackup: lastBackup) != nil
    }
    
    // MARK: Private functions
    
    private func nextBackup(lastBackup: Date) -> Date? {
        let referenceDate = lastBackup.startOfDay
        let nextBackupDate: Date? = {
            switch frequency {
            case .never: return nil
            case .instant: return calendar.startOfDay(for: Date.today)
            case .daily: return calendar.date(byAdding: .day, value: 1, to: referenceDate)
            case .weekly: return calendar.date(byAdding: .weekOfYear, value: 1, to: referenceDate)
            case .monthly: return calendar.date(byAdding: .month, value: 1, to: referenceDate)
            case .yearly: return calendar.date(byAdding: .year, value: 1, to: referenceDate)
            }
        }()
        guard let nextBackupDate else { return nil }
        guard nextBackupDate.isInFuture else { return Date.today }
        return nextBackupDate
    }
    
    // MARK: Enum
    
    public enum Frequency {
        case never
        case instant
        case daily
        case weekly
        case monthly
        case yearly
    }
}
