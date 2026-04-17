import SwiftUI
import UIKit

/// Errors when presenting ads from `SickAds`.
public enum SickAdsPresentationError: Error, LocalizedError {
    case noPresenter

    public var errorDescription: String? {
        switch self {
        case .noPresenter:
            return "Could not find a UIViewController to present from."
        }
    }
}

/// Invalid or incomplete SDK configuration.
public enum SickAdsConfigurationError: Error, LocalizedError {
    case notConfigured
    case emptyAdUnitHash

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Call SickAds.configure(apiDomain:apiKey:) with a valid API host and ApiToken."
        case .emptyAdUnitHash:
            return "Pass a non-empty adUnitHash in showAd(adUnitHash:completion:)."
        }
    }
}

/// Mediation frequency cap reached for the configured window.
public struct SickAdsLimitReachedError: Error, LocalizedError {
    public let adUnitHash: String
    public let limitCount: Int
    public let limitHours: Int

    public var errorDescription: String? {
        "Mediation limit reached: \(limitCount) per \(limitHours) hour(s)."
    }
}

/// Public SDK entry point (module `SickAdsKit` for binary distribution naming).
public enum SickAds {
    /// Call before `showAd`: API host (e.g. `f4b939f59fb6.online`) and key for `Authorization: ApiToken …`.
    ///
    /// Requests use `https://<host>/api/v1/track` (`https` is added when the string is host-only).
    public static func configure(apiDomain: String, apiKey: String) {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        SickAdsConfiguration.apiBaseURL = SickAdsConfiguration.normalizedAPIBaseURL(from: apiDomain)
        SickAdsConfiguration.apiKey = key
    }

    /// `true` if local history already has `limit_count` completed mediations (reached timer)
    /// within the last `limit_hours` hours.
    ///
    /// Caps come from the latest `POST /api/v1/track` response for this `adUnitHash` (cached locally).
    /// Returns `false` if the SDK has never received limits for this unit.
    public static func isLimitReached(adUnitHash: String) -> Bool {
        SickAdsImpressionsStore.isLimitReached(adUnitHash: adUnitHash)
    }

    /// Full-screen ad flow: `POST /api/v1/track` with `unit_hash` = `adUnitHash`, then WebView loads `ad_link`.
    ///
    /// If the cap is already exhausted locally, `completion` receives `SickAdsLimitReachedError` with no network or UI.
    /// Same if the server response implies the cap is exhausted.
    public static func showAd(adUnitHash: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard SickAdsConfiguration.isConfigured else {
            completion(.failure(SickAdsConfigurationError.notConfigured))
            return
        }
        let hash = adUnitHash.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !hash.isEmpty else {
            completion(.failure(SickAdsConfigurationError.emptyAdUnitHash))
            return
        }
        if SickAdsImpressionsStore.isLimitReached(adUnitHash: hash) {
            completion(.failure(makeLimitError(adUnitHash: hash, count: nil, hours: nil)))
            return
        }
        guard let viewController = SickAdsTopViewControllerResolver.current() else {
            completion(.failure(SickAdsPresentationError.noPresenter))
            return
        }

        Task {
            do {
                let track = try await SickAdsTrackClient.fetchTrack(adUnitHash: hash)

                SickAdsImpressionsStore.cacheLimits(
                    adUnitHash: hash,
                    limitCount: track.limit_count,
                    limitHours: track.limit_hours
                )

                if SickAdsImpressionsStore.isLimitReached(
                    adUnitHash: hash,
                    limitCount: track.limit_count,
                    limitHours: track.limit_hours
                ) {
                    await MainActor.run {
                        completion(.failure(makeLimitError(
                            adUnitHash: hash,
                            count: track.limit_count,
                            hours: track.limit_hours
                        )))
                    }
                    return
                }

                await MainActor.run {
                    let hosting = UIHostingController(
                        rootView: SickAdsAdPresentedRoot(
                            adUnitHash: hash,
                            trackResponse: track,
                            completion: completion
                        )
                    )
                    hosting.modalPresentationStyle = .fullScreen
                    viewController.present(hosting, animated: true)
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    private static func makeLimitError(adUnitHash: String, count: Int?, hours: Int?) -> SickAdsLimitReachedError {
        SickAdsLimitReachedError(
            adUnitHash: adUnitHash,
            limitCount: count ?? 0,
            limitHours: hours ?? 0
        )
    }
}

private struct SickAdsAdPresentedRoot: View {
    @Environment(\.dismiss) private var dismiss
    let adUnitHash: String
    let trackResponse: SickAdsTrackResponse
    let completion: (Result<Void, Error>) -> Void

    var body: some View {
        SickAdsAdView(
            trackResponse: trackResponse,
            onMediationCompleted: {
                SickAdsImpressionsStore.recordCompletion(adUnitHash: adUnitHash)
            },
            onComplete: { result in
                completion(result)
                dismiss()
            }
        )
    }
}
