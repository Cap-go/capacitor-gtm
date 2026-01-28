// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapgoCapacitorGtm",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "CapgoCapacitorGtm",
            targets: ["GoogleTagManagerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/googleanalytics/google-tag-manager-ios-sdk.git", exact: "7.4.6")
    ],
    targets: [
        .target(
            name: "GoogleTagManagerPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "GoogleTagManager", package: "google-tag-manager-ios-sdk")
            ],
            path: "ios/Sources/GoogleTagManagerPlugin"),
        .testTarget(
            name: "GoogleTagManagerPluginTests",
            dependencies: ["GoogleTagManagerPlugin"],
            path: "ios/Tests/GoogleTagManagerPluginTests")
    ]
)
