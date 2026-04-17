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
            url: "https://github.com/SickAds/sickads-ios-sdk/releases/download/0.4.3/SickAdsKit.xcframework.zip",
            checksum: "9d4aee722cddabf20b4f3ac6ae463233f89a7f6f32970e2936b7d6e29eb5482c"
        ),
    ]
)
