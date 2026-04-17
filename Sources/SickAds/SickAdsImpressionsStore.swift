import Foundation

/// Local history of completed mediations (reached timer) and last known caps for `isLimitReached`.
enum SickAdsImpressionsStore {
    private static let timestampsKeyPrefix = "7c2f0e9a4d183b56a1c8f503e2d7946b"
    private static let limitCountKeyPrefix = "91e3d7b2c5f04a8e9d106b3c7a2f8e41"
    private static let limitHoursKeyPrefix = "b304e9c2a7f15d4382b06e9c5a1f7d30"

    private static let defaults = UserDefaults.standard
    private static let queue = DispatchQueue(label: "c4ede78109f32a5bc8d067e31b94a2f0.queue")

    // MARK: - Public

    /// Records a completed mediation (user reached the timer). Appends current timestamp.
    static func recordCompletion(adUnitHash: String) {
        let key = normalize(adUnitHash)
        guard !key.isEmpty else { return }
        queue.sync {
            var history = loadTimestamps(adUnitHash: key)
            history.append(Date().timeIntervalSince1970)
            history = trimmed(history, withinHours: 24 * 30)
            defaults.set(history, forKey: timestampsKeyPrefix + key)
        }
    }

    /// Caches the latest `limit_count` / `limit_hours` from the track response for this unit.
    static func cacheLimits(adUnitHash: String, limitCount: Int?, limitHours: Int?) {
        let key = normalize(adUnitHash)
        guard !key.isEmpty else { return }
        queue.sync {
            if let count = limitCount, count > 0 {
                defaults.set(count, forKey: limitCountKeyPrefix + key)
            }
            if let hours = limitHours, hours > 0 {
                defaults.set(hours, forKey: limitHoursKeyPrefix + key)
            }
        }
    }

    /// `true` if completed mediations in the last `limitHours` hours are >= `limitCount`.
    /// If caps are unknown (no args and no cache), returns `false`.
    static func isLimitReached(
        adUnitHash: String,
        limitCount: Int? = nil,
        limitHours: Int? = nil
    ) -> Bool {
        let key = normalize(adUnitHash)
        guard !key.isEmpty else { return false }
        return queue.sync {
            let cachedCount = defaults.integer(forKey: limitCountKeyPrefix + key)
            let cachedHours = defaults.integer(forKey: limitHoursKeyPrefix + key)
            let count = (limitCount ?? 0) > 0 ? limitCount! : cachedCount
            let hours = (limitHours ?? 0) > 0 ? limitHours! : cachedHours
            guard count > 0, hours > 0 else { return false }
            let history = loadTimestamps(adUnitHash: key)
            let recent = trimmed(history, withinHours: TimeInterval(hours))
            return recent.count >= count
        }
    }

    // MARK: - Internals

    private static func loadTimestamps(adUnitHash: String) -> [TimeInterval] {
        let raw = defaults.array(forKey: timestampsKeyPrefix + adUnitHash) ?? []
        return raw.compactMap { ($0 as? NSNumber)?.doubleValue ?? ($0 as? Double) }
    }

    private static func trimmed(_ timestamps: [TimeInterval], withinHours hours: TimeInterval) -> [TimeInterval] {
        let cutoff = Date().timeIntervalSince1970 - hours * 3600
        return timestamps.filter { $0 >= cutoff }.sorted()
    }

    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
