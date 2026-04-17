// swift-tools-version: 5.9
import PackageDescription

/// Бинарный XCFramework: [Releases](https://github.com/SickAds/sickads-ios-sdk/releases).
/// Локальная пересборка: `./Scripts/build-xcframework.sh` (скрипт не в публичном репо).
///
/// В приложении: `import SickAdsKit`, `SickAds.setApiKey` / `showAd(completion:)`.
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
            url: "https://github.com/SickAds/sickads-ios-sdk/releases/download/0.2/SickAdsKit.xcframework.zip",
            checksum: "11614ccfdb90674ba435298d37b9780a6f30b475cb5e3aa8c475ce8784442e91"
        ),
    ]
)
