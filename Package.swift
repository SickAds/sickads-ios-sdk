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
            url: "https://github.com/SickAds/sickads-ios-sdk/releases/download/0.4.1/SickAdsKit.xcframework.zip",
            checksum: "2c91ea399ff7ee1028a66da415c0fa11c092fd9131ec5b407b9377b048c49810"
        ),
    ]
)
