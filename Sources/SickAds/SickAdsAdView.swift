import SwiftUI
import WebKit

public struct SickAdsAdView: View {
    @State private var viewModel: SickAdsAdViewModel
    @State private var didCompleteMediation = false

    private let onComplete: (Result<Void, Error>) -> Void

    /// Mediation UI driven by `POST /api/v1/track` (`ad_link`, `timer_seconds` / `timeout_sec`).
    /// `onMediationCompleted` runs once when the user reaches the timer.
    public init(
        trackResponse: SickAdsTrackResponse,
        onMediationCompleted: (() -> Void)? = nil,
        onComplete: @escaping (Result<Void, Error>) -> Void
    ) {
        let trimmed = trackResponse.ad_link.trimmingCharacters(in: .whitespacesAndNewlines)
        let url = URL(string: trimmed) ?? URL(string: "about:blank")!
        let seconds = trackResponse.timer_seconds ?? trackResponse.timeout_sec
        let model = SickAdsAdViewModel(startURL: url, mediationCountdownSeconds: seconds)
        model.onMediationCompleted = onMediationCompleted
        _viewModel = State(initialValue: model)
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            Color(red: 0.14, green: 0.14, blue: 0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                

                SickAdsAdEmbeddedWebView(
                    startURL: viewModel.startURL,
                    reloadID: viewModel.reloadID,
                    onLoadingStateChange: { isLoading in
                        print("Loading: [\(isLoading)]")
                        viewModel.setLoading(isLoading)
                    },
                    onMainFrameNavigation: viewModel.handleMainFrameNavigation,
                    onReload: viewModel.resetFromWebReload,
                    onMailOrTel: finishMediationSuccess
                )
                .overlay {
                    if viewModel.isLoading {
                        WebLoadingOverlay()
                    }
                }
                .overlay(alignment: .top) {
                    if viewModel.currentStep == .yellowBlocks {
                        StepOneArrowOverlay()
                    } else if viewModel.currentStep == .searchResults {
                        StepTwoArrowOverlay()
                    }
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .overlay {
                VStack {
                    header
                    Spacer()
                }
            }
        }
        .onAppear(perform: viewModel.refreshCountdownIfNeeded)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.refreshCountdownIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.refreshCountdownIfNeeded()
        }
    }

    private func finishMediationSuccess() {
        guard !didCompleteMediation else { return }
        didCompleteMediation = true
        onComplete(.success(()))
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool { verticalSizeClass == .compact }

    @ViewBuilder
    private var header: some View {
        if viewModel.showReward {
            HeaderSectionView {
                RewardHeaderView(compact: isLandscape) {
                    viewModel.handleCollectTap()
                    finishMediationSuccess()
                }
            }
            .frame(height: isLandscape ? 56 : 162)
        } else {
            switch viewModel.currentStep {
            case .loading:
                HeaderSectionView {
                    HeaderCardView(
                        stepText: "",
                        title: "Loading…",
                        cardWidth: 279,
                        cardHeight: 60,
                        compact: isLandscape
                    )
                }
                .frame(height: isLandscape ? 56 : 164)
            case .yellowBlocks:
                HeaderSectionView {
                    HeaderCardView(
                        stepText: "Step 1 / 3",
                        title: "Tap on any orange box",
                        cardWidth: 279,
                        cardHeight: 60,
                        compact: isLandscape
                    )
                }
                .frame(height: isLandscape ? 56 : 164)
            case .searchResults:
                HeaderSectionView {
                    HeaderCardView(
                        stepText: "Step 2 / 3",
                        title: "Tap “Visit Website” to continue",
                        cardWidth: 243,
                        cardHeight: 84,
                        compact: isLandscape
                    )
                }
                .frame(height: isLandscape ? 56 : 164)
            case .adSite:
                HeaderSectionView {
                    StepThreeHeaderView(
                        totalSeconds: viewModel.mediationCountdownSeconds,
                        remainingSeconds: viewModel.remainingSeconds,
                        compact: isLandscape
                    )
                }
                .frame(height: isLandscape ? 56 : 164)
            }
        }
    }
}

private struct HeaderSectionView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .background(Color(red: 0.192, green: 0.192, blue: 0.192))
    }
}

private struct HeaderCardView: View {
    let stepText: String
    let title: String
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    var compact: Bool = false

    var body: some View {
        if compact {
            HStack(spacing: 12) {
                stepBadge
                    .fixedSize()

                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white)

                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .padding(.horizontal, 14)
                }
                .frame(height: 36)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                headerLabel

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white)

                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .padding(.horizontal, 16)
                }
                .frame(width: cardWidth, height: cardHeight)
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: .infinity)
            }
        }
    }

    private var stepBadge: some View {
        HStack(spacing: 0) {
            Text(stepText.replacingOccurrences(of: " / 3", with: ""))
                .foregroundStyle(.white)
            Text(" / 3")
                .foregroundStyle(Color.white.opacity(0.3))
        }
        .font(.system(size: 15, weight: .semibold))
    }

    private var headerLabel: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(stepText.replacingOccurrences(of: " / 3", with: ""))
                    .foregroundStyle(.white)

                Text(" / 3")
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .font(.system(size: 20, weight: .semibold))
            .frame(height: 36)

            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 2)
                .padding(.top, 2)
        }
    }
}

private struct StepThreeHeaderView: View {
    let totalSeconds: Int
    let remainingSeconds: Int
    var compact: Bool = false

    private var progress: CGFloat {
        let d = max(totalSeconds, 1)
        return CGFloat(d - remainingSeconds) / CGFloat(d)
    }

    private var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        if compact {
            HStack(spacing: 16) {
                HStack(spacing: 0) {
                    Text("Step 3")
                        .foregroundStyle(.white)
                    Text(" / 3")
                        .foregroundStyle(Color.white.opacity(0.3))
                }
                .font(.system(size: 15, weight: .semibold))
                .fixedSize()

                Text("Please wait \(formattedTime)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .fixedSize()

                ProgressTrackView(progress: progress)
                    .frame(height: 8)
                    .frame(maxWidth: 160)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text("Step 3 / 3")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 36)

                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 2)
                        .padding(.top, 2)
                }

                VStack(spacing: 16) {
                    Text("Almost done!\nPlease wait \(formattedTime)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    ProgressTrackView(progress: progress)
                        .frame(width: 255, height: 8)
                }
                .frame(maxWidth: .infinity, minHeight: 120, maxHeight: .infinity)
            }
        }
    }
}

private struct RewardHeaderView: View {
    var compact: Bool = false
    let action: () -> Void

    var body: some View {
        if compact {
            HStack(spacing: 16) {
                Text("Your reward is ready!")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .fixedSize()

                Button(action: action) {
                    Text("Collect")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 120, height: 36)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color(red: 0.98, green: 0.76, blue: 0.07))
                        )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text("Your reward is ready!")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Button(action: action) {
                        Text("Collect")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 255, height: 50)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color(red: 0.98, green: 0.76, blue: 0.07))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct ProgressTrackView: View {
    let progress: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.28))

            Capsule()
                .fill(Color(red: 0.98, green: 0.73, blue: 0.05))
                .frame(width: 255 * max(0, min(progress, 1)))
        }
    }
}

private struct SickAdsAdEmbeddedWebView: UIViewRepresentable {
    let startURL: URL
    let reloadID: UUID
    let onLoadingStateChange: @MainActor (Bool) -> Void
    let onMainFrameNavigation: @MainActor (URL?) -> Void
    let onReload: @MainActor () -> Void
    let onMailOrTel: @MainActor () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onLoadingStateChange: onLoadingStateChange,
            onMainFrameNavigation: onMainFrameNavigation,
            onReload: onReload,
            onMailOrTel: onMailOrTel
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.lastReloadID = reloadID
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: startURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onLoadingStateChange = onLoadingStateChange
        context.coordinator.onMainFrameNavigation = onMainFrameNavigation
        context.coordinator.onReload = onReload
        context.coordinator.onMailOrTel = onMailOrTel

        if context.coordinator.lastReloadID != reloadID {
            context.coordinator.lastReloadID = reloadID
            Task { @MainActor in
                onReload()
                onLoadingStateChange(true)
            }
            webView.load(URLRequest(url: startURL))
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastReloadID: UUID?
        var onLoadingStateChange: @MainActor (Bool) -> Void
        var onMainFrameNavigation: @MainActor (URL?) -> Void
        var onReload: @MainActor () -> Void
        var onMailOrTel: @MainActor () -> Void

        init(
            onLoadingStateChange: @escaping @MainActor (Bool) -> Void,
            onMainFrameNavigation: @escaping @MainActor (URL?) -> Void,
            onReload: @escaping @MainActor () -> Void,
            onMailOrTel: @escaping @MainActor () -> Void
        ) {
            self.onLoadingStateChange = onLoadingStateChange
            self.onMainFrameNavigation = onMainFrameNavigation
            self.onReload = onReload
            self.onMailOrTel = onMailOrTel
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            let url = navigationAction.request.url
            let scheme = url?.scheme?.lowercased()
            let isHTTPFamily = scheme == "http" || scheme == "https"

            if scheme == "mailto" || scheme == "tel" || scheme == "telprompt" {
                Task { @MainActor in
                    onMailOrTel()
                }
                decisionHandler(.allow)
                return
            }

            if navigationAction.targetFrame?.isMainFrame == true {
                Task { @MainActor in
                    onLoadingStateChange(true)
                    onMainFrameNavigation(url)
                }
                decisionHandler(.allow)
                return
            }

            // target="_blank" / window.open: no targetFrame — load in this WebView and treat as main-frame navigation.
            if navigationAction.targetFrame == nil, isHTTPFamily {
                Task { @MainActor in
                    onLoadingStateChange(true)
                    onMainFrameNavigation(url)
                }
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                onLoadingStateChange(false)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                onLoadingStateChange(false)
            }
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            Task { @MainActor in
                onLoadingStateChange(false)
            }
        }
    }
}

private struct WebLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.18)

            ProgressView()
                .controlSize(.large)
                .tint(.white)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.black.opacity(0.42))
                )
        }
        .allowsHitTesting(false)
    }
}

private struct StepOneArrowOverlay: View {
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { _ in
                StepOneArrowView()
            }
        }
        .frame(width: 314)
        .padding(.top, -32)
        .allowsHitTesting(false)
    }
}

private struct StepTwoArrowOverlay: View {
    var body: some View {
        StepTwoArrowView()
            .padding(.top, -92)
            .allowsHitTesting(false)
    }
}

private struct StepOneArrowView: View {
    var body: some View {
        Image("ArrowDown", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 73.5, height: 175)
    }
}

private struct StepTwoArrowView: View {
    var body: some View {
        Image("SmallArrowDown", bundle: .module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 74, height: 260)
    }
}
