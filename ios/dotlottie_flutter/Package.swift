// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "dotlottie_flutter",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "dotlottie-flutter", targets: ["dotlottie_flutter"])
    ],
    dependencies: [
        .package(url: "https://github.com/LottieFiles/dotlottie-ios.git", from: "0.15.6"),
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "dotlottie_flutter",
            dependencies: [
                .product(name: "DotLottie", package: "dotlottie-ios"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
