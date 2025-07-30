// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapgoCapactiorGtm",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CapgoCapactiorGtm",
            targets: ["GoogleTagManagerPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "GoogleTagManagerPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/GoogleTagManagerPlugin"),
        .testTarget(
            name: "GoogleTagManagerPluginTests",
            dependencies: ["GoogleTagManagerPlugin"],
            path: "ios/Tests/GoogleTagManagerPluginTests")
    ]
)
