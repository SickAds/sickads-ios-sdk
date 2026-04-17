import Foundation

public struct SickAdsTrackResponse: Decodable, Sendable {
    public let ad_link: String
    public let timeout_sec: Int
    public let limit_count: Int?
    public let limit_hours: Int?
    public let timer_seconds: Int?
}

public enum SickAdsTrackError: Error, LocalizedError, Sendable {
    case notConfigured
    case invalidBaseURL
    case invalidResponse
    case httpStatus(code: Int, body: String?)

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Set apiDomain and apiKey via SickAds.configure, and pass a non-empty adUnitHash to showAd(adUnitHash:)."
        case .invalidBaseURL:
            return "Invalid apiDomain."
        case .invalidResponse:
            return "Could not parse the track endpoint response."
        case let .httpStatus(code, body):
            if let body, !body.isEmpty {
                return "Track endpoint returned \(code): \(body)"
            }
            return "Track endpoint returned status code \(code)."
        }
    }
}

enum SickAdsTrackClient {
    static func fetchTrack(adUnitHash: String) async throws -> SickAdsTrackResponse {
        let unitHash = adUnitHash.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let base = SickAdsConfiguration.apiBaseURL,
              let key = SickAdsConfiguration.apiKey, !key.isEmpty,
              !unitHash.isEmpty
        else {
            throw SickAdsTrackError.notConfigured
        }

        var trackURL = base
        for segment in ["api", "v1", "track"] {
            trackURL.appendPathComponent(segment)
        }

        var body: [String: String] = [
            "unit_hash": unitHash,
            "device_id": SickAdsInstallationID.uuidString,
        ]
        if let bundleId = Bundle.main.bundleIdentifier, !bundleId.isEmpty {
            body["bundle_id"] = bundleId
        }

        var request = URLRequest(url: trackURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ApiToken \(key)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SickAdsTrackError.invalidResponse
        }

        guard (200 ... 299).contains(http.statusCode) else {
            let text = String(data: data, encoding: .utf8)
            throw SickAdsTrackError.httpStatus(code: http.statusCode, body: text)
        }

        do {
            return try JSONDecoder().decode(SickAdsTrackResponse.self, from: data)
        } catch {
            throw SickAdsTrackError.invalidResponse
        }
    }
}
