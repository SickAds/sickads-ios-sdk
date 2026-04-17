import Foundation

enum SickAdsConfiguration {
    static var apiBaseURL: URL?
    static var apiKey: String?

    static var isConfigured: Bool {
        apiBaseURL != nil && !(apiKey?.isEmpty ?? true)
    }

    /// Normalizes API host: trimmed, `https` scheme, host only (+ optional port).
    static func normalizedAPIBaseURL(from domain: String) -> URL? {
        var s = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return nil }
        if !s.contains("://") {
            s = "https://\(s)"
        }
        guard let parsed = URL(string: s), let host = parsed.host, !host.isEmpty else {
            return nil
        }
        var c = URLComponents()
        c.scheme = parsed.scheme?.lowercased() ?? "https"
        c.host = host
        c.port = parsed.port
        return c.url
    }
}
