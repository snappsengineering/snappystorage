**snappystorage**

Usage:

Define a model

```
import Foundation
import SnappyStorage

struct Activity: Storable {
    var id: String
    var name: String
    var value: String
    var date: Date
    
    init(
        id: String = generateHexID(),
        name: String,
        value: String = "",
        date: Date
    ) {
        self.id = id
        self.name = name
        self.value = value
        self.date = date
    }
}
```

Define a service

```
import Foundation
import SnappyStorage

final class ActivityService: Service<Activity> {
    static let shared = ActivityService()
    
    func load(for date: Date) -> [Activity] {
        return collection.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted(by: { $0.date < $1.date })
    }
    
    func loadAll() -> [Activity] {
        return collection.sorted(by: { $0.date < $1.date })
    }
}
```

Use!

```
dailyActivities = ActivityService.shared.load(for: date) // Returns activities for date
```

Combine Publisher documentation
Coming Soon!
