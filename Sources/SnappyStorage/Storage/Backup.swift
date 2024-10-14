//
//  Backup.swift
//  SnappyStorage
//
//  Created by Shane Noormohamed on 2024-10-13.
//

import Foundation

struct Backup {
    
    enum Frequency {
        case never
        case instant
        case daily
        case weekly
        case monthly
        case yearly
    }

    var lastBackupDate: Date?
    var frequency: Frequency = .daily
   
    func nextBackup(date: Frequency) -> Date? {
        let referenceDate = (lastBackupDate ?? Date.today).startOfDay
        let nextBackupDate: Date? = {
            switch frequency {
            case .never: return nil
            case .instant: return Calendar.current.startOfDay(for: Date.today)
            case .daily: return Calendar.current.date(byAdding: .day, value: 1, to: referenceDate)
            case .weekly: return Calendar.current.date(byAdding: .weekOfYear, value: 1, to: referenceDate)
            case .monthly: return Calendar.current.date(byAdding: .month, value: 1, to: referenceDate)
            case .yearly: return Calendar.current.date(byAdding: .year, value: 1, to: referenceDate)
            }
        }()
        guard let nextBackupDate else { return nil }
        guard nextBackupDate.isInFuture else { return Date.today }
        return nextBackupDate
    }
    
    var shouldBackup: Bool {
        guard frequency != .never else { return false }
        return nextBackup(date: frequency) == Date.today
    }
}
