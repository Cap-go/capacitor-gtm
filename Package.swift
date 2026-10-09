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
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "11.15.0")
    ],
    targets: [
        .target(
            name: "GoogleTagManagerPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk")
            ],
            path: "ios/Sources/GoogleTagManagerPlugin"),
        .testTarget(
            name: "GoogleTagManagerPluginTests",
            dependencies: ["GoogleTagManagerPlugin"],
            path: "ios/Tests/GoogleTagManagerPluginTests")
    ]
)
