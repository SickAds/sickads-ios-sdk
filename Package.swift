// swift-tools-version: 5.9
import PackageDescription

/// Бинарный XCFramework: [Releases](https://github.com/SickAds/sickads-ios-sdk/releases).
/// Локальная пересборка: `./Scripts/build-xcframework.sh` (скрипт не в публичном репо).
///
/// В приложении: `import GrocksAdsKit`, `GrocksAds.setApiKey` / `showAd(completion:)`.
let package = Package(
    name: "GrocksAds",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "GrocksAds",
            targets: ["GrocksAdsKit"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "GrocksAdsKit",
            url: "https://github.com/SickAds/sickads-ios-sdk/releases/download/0.1/GrocksAdsKit.xcframework.zip",
            checksum: "a1841bb56c6341731448e93fb6a216004be44c596c7ea64198146a00ca8333c1"
        ),
    ]
)
