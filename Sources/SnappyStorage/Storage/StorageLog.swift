import Foundation
#if canImport(os)
import os
#endif

enum StorageLog {
    static func warning(_ message: String, category: String) {
        #if canImport(os)
        Logger(subsystem: "com.snappsengineering.snappystorage", category: category)
            .warning("\(message)")
        #else
        print("SnappyStorage warning [\(category)]: \(message)")
        #endif
    }
}
