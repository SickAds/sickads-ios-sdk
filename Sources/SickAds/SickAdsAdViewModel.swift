import Foundation
import Observation

enum SickAdsAdStep {
    case loading
    case yellowBlocks
    case searchResults
    case adSite
}

private final class CountdownTaskBox {
    var task: Task<Void, Never>?

    deinit {
        task?.cancel()
    }
}

@MainActor
@Observable
final class SickAdsAdViewModel {
    /// Step 3 mediation timer length (seconds), from `timer_seconds` or `timeout_sec` in the track response.
    let mediationCountdownSeconds: Int

    /// Count of distinct main-frame navigations (normalized URL changes).
    private(set) var mainFrameRedirectCount = 0
    var isLoading = true
    var showReward = false

    var currentStep: SickAdsAdStep {
        if isLoading { return .loading }
        if mainFrameRedirectCount <= 1 { return .yellowBlocks }
        if mainFrameRedirectCount <= 2 { return .searchResults }
        return .adSite
    }

    var remainingSeconds: Int
    var reloadID = UUID()
    let startURL: URL

    /// Fired **once** when the user reaches the timer (mediation counts as completed).
    var onMediationCompleted: (() -> Void)?

    private var lastMainFrameNormalizedURL: String?
    private var adCountdownStarted = false
    private var didFireMediationCompleted = false
    private let countdownTaskBox = CountdownTaskBox()
    private var countdownDeadline: Date?

    init(startURL: URL, mediationCountdownSeconds: Int) {
        self.startURL = startURL
        let capped = max(1, mediationCountdownSeconds)
        self.mediationCountdownSeconds = capped
        self.remainingSeconds = capped
    }

    func resetFromWebReload() {
        mainFrameRedirectCount = 0
        lastMainFrameNormalizedURL = nil
        adCountdownStarted = false
        showReward = false
        countdownTaskBox.task?.cancel()
        countdownTaskBox.task = nil
        countdownDeadline = nil
        remainingSeconds = mediationCountdownSeconds
    }

    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    func handleCollectTap() {
        countdownTaskBox.task?.cancel()
        countdownTaskBox.task = nil
    }

    func handleMainFrameNavigation(to url: URL?) {
        print("Navigation: [\(url?.absoluteString ?? "nil")]")
        guard let url else { return }

        let normalized = normalizedURL(url)
        guard normalized != lastMainFrameNormalizedURL else { return }
        lastMainFrameNormalizedURL = normalized
        mainFrameRedirectCount += 1
        print("Redirect Count: [\(mainFrameRedirectCount)]")

        if mainFrameRedirectCount >= 3, !adCountdownStarted, !showReward {
            adCountdownStarted = true
            startCountdown()
        }
    }

    func refreshCountdownIfNeeded() {
        guard countdownDeadline != nil, !showReward else { return }
        syncRemainingSecondsWithDeadline()

        if countdownDeadline != nil, countdownTaskBox.task == nil {
            startCountdownLoop()
        }
    }

    private func startCountdown() {
        print("Start Countdown")
        countdownTaskBox.task?.cancel()
        remainingSeconds = mediationCountdownSeconds
        countdownDeadline = Date().addingTimeInterval(TimeInterval(remainingSeconds))
        startCountdownLoop()
        if !didFireMediationCompleted {
            didFireMediationCompleted = true
            onMediationCompleted?()
        }
    }

    private func startCountdownLoop() {
        countdownTaskBox.task?.cancel()

        countdownTaskBox.task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self?.syncRemainingSecondsWithDeadline()
                }
            }
        }
    }

    private func syncRemainingSecondsWithDeadline() {
        guard let countdownDeadline else { return }

        let secondsLeft = max(0, Int(ceil(countdownDeadline.timeIntervalSinceNow)))

        if secondsLeft > 0 {
            remainingSeconds = secondsLeft
        } else {
            countdownTaskBox.task?.cancel()
            countdownTaskBox.task = nil
            self.countdownDeadline = nil
            remainingSeconds = 0
            showReward = true
        }
    }

    private func normalizedURL(_ url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.fragment = nil
        return components?.string ?? url.absoluteString
    }
}
