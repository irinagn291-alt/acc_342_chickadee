import Foundation

/// Day identity is YYYYMMDD from `Calendar.startOfDay`. Streak walks these keys.
enum DayKey {
    static func int(for date: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return year * 10_000 + month * 100 + day
    }

    static func date(from key: Int, calendar: Calendar = .current) -> Date? {
        var parts = DateComponents()
        parts.year = key / 10_000
        parts.month = (key / 100) % 100
        parts.day = key % 100
        parts.calendar = calendar
        parts.timeZone = calendar.timeZone
        guard let date = calendar.date(from: parts) else { return nil }
        return calendar.startOfDay(for: date)
    }

    static func adding(days: Int, to key: Int, calendar: Calendar = .current) -> Int? {
        guard let date = date(from: key, calendar: calendar),
              let shifted = calendar.date(byAdding: .day, value: days, to: date) else {
            return nil
        }
        return int(for: shifted, calendar: calendar)
    }
}
