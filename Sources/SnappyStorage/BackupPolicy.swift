//
//  BackupPolicy.swift
//  SnappyStorage
//
//  Created by snapps engineering ltd.
//

import Foundation

public struct BackupPolicy {
    
    private let calendar: Calendar = .current
    
    var frequency: Frequency
    
    init(frequency: Frequency) {
        self.frequency = frequency
    }
    
    func shouldBackup(lastBackup: Date) -> Bool {
        return nextBackup(lastBackup: lastBackup) != nil
    }
    
    private func nextBackup(lastBackup: Date) -> Date? {
        let referenceDate = lastBackup
        let nextBackupDate: Date? = {
            switch frequency {
            case .instant: return calendar.startOfDay(for: Date())
            case .daily: return calendar.date(byAdding: .day, value: 1, to: referenceDate)
            case .weekly: return calendar.date(byAdding: .weekOfYear, value: 1, to: referenceDate)
            case .monthly: return calendar.date(byAdding: .month, value: 1, to: referenceDate)
            case .yearly: return calendar.date(byAdding: .year, value: 1, to: referenceDate)
            }
        }()
        guard let nextBackupDate else { return nil }
        guard nextBackupDate > Date() else { return Date() }
        return nextBackupDate
    }
    
    // MARK: Enum
    
    enum Frequency {
        case instant
        case daily
        case weekly
        case monthly
        case yearly
    }
}
