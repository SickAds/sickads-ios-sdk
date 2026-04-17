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
            url: "https://github.com/SickAds/sickads-ios-sdk/releases/download/0.4.2/SickAdsKit.xcframework.zip",
            checksum: "87d3871acbad2c04b205a46db81f9ddd4d4451477bc2216b66ff913bf97d9999"
        ),
    ]
)
