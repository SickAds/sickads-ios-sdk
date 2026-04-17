import Foundation

/// Stable per-install device identifier (UUID v4), persisted in `UserDefaults`.
enum SickAdsInstallationID {
    private static let storageKey = "f8a31c2e9d045b67e4a108f3c6d2b951"

    /// Lowercase `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx` (same shape as `UUID.uuidString`).
    static var uuidString: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: storageKey),
           UUID(uuidString: existing) != nil
        {
            return existing
        }
        let fresh = UUID().uuidString.lowercased()
        defaults.set(fresh, forKey: storageKey)
        return fresh
    }
}
