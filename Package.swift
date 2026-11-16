// swift-tools-version:6.0
// AuthAgent: a sign-in flow (Sign In, Sign Up, a one-time code sent by email, a reset sheet) as plain SwiftUI in an
// app's own look and words, written from templates, as a Granite agent package. An app that links it finds the
// `auth` agent through Granite's roster, with nothing listed by hand.

import PackageDescription

let package = Package(
    name: "AuthAgent",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AuthAgent", targets: ["AuthAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/riteshpakala/Granite.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "AuthAgent",
            dependencies: [.product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(
            name: "AuthAgentTests",
            dependencies: ["AuthAgent", .product(name: "GraniteAgents", package: "Granite")],
            swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
