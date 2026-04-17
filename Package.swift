// swift-tools-version: 5.9
import PackageDescription

/// Бинарный XCFramework: [Releases](https://github.com/SickAds/sickads-ios-sdk/releases).
/// Исходники не публикуются; локальная сборка: `./Scripts/build-xcframework.sh`.
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
        .binaryTarget(
            name: "SickAdsKit",
            url: "https://github.com/SickAds/sickads-ios-sdk/releases/download/0.4.0/SickAdsKit.xcframework.zip",
            checksum: "258aee92692bc5388f490155a44ce22eeb138f7054a981b8152f5a02b65949c7"
        ),
    ]
)
