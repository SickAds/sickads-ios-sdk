// swift-tools-version: 5.9
import PackageDescription

/// Исходный Swift Package: таргет `SickAdsKit`, продукт `SickAds`.
///
/// В приложении: `import SickAdsKit`, затем `SickAds.configure(apiDomain:apiKey:)` и `showAd(adUnitHash:completion:)`.
let package = Package(
    name: "SickAds",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "SickAds",
            targets: ["SickAdsKit"]
        ),
    ],
    targets: [
        .target(
            name: "SickAdsKit",
            path: "Sources/SickAds",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
