import Foundation

final class RateLimiter {
    private let perMinuteLimit: Int
    private let dailyLimit: Int
    private let dailyCountKey = "RateLimiter_dailyCount"
    private let dailyDateKey = "RateLimiter_dailyDate"

    private var recentTimestamps: [Date] = []

    init(perMinuteLimit: Int = 10, dailyLimit: Int = 50) {
        self.perMinuteLimit = perMinuteLimit
        self.dailyLimit = dailyLimit
    }

    func checkAndRecord() throws {
        let now = Date()

        // --- Per-minute (rolling window) ---
        let windowStart = now.addingTimeInterval(-60)
        recentTimestamps.removeAll { $0 < windowStart }

        if recentTimestamps.count >= perMinuteLimit {
            throw RateLimitError.perMinute
        }

        // --- Daily (calendar day, persisted) ---
        let todayString = Self.dayString(for: now)
        let defaults = UserDefaults.standard

        let storedDate = defaults.string(forKey: dailyDateKey) ?? ""
        var dailyCount = defaults.integer(forKey: dailyCountKey)

        if storedDate != todayString {
            dailyCount = 0
            defaults.set(todayString, forKey: dailyDateKey)
        }

        if dailyCount >= dailyLimit {
            throw RateLimitError.daily(limit: dailyLimit)
        }

        // All checks passed — record the request
        recentTimestamps.append(now)
        defaults.set(dailyCount + 1, forKey: dailyCountKey)
    }

    private static func dayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
}

enum RateLimitError: LocalizedError {
    case perMinute
    case daily(limit: Int)

    var errorDescription: String? {
        switch self {
        case .perMinute:
            return "Too many requests. Please wait a moment."
        case .daily(let limit):
            return "You've reached the daily limit of \(limit) AI estimates."
        }
    }
}
