// swift-tools-version: 6.2

import PackageDescription

// RFC 3339: Date and Time on the Internet: Timestamps
//
// Implements RFC 3339 date-time format for internet protocols.
// RFC 3339 is a profile of ISO 8601, specifying a specific subset with:
// - Extended format only (with separators)
// - Full precision (no truncation)
// - Explicit timezone offset required
//
// This is a pure Swift implementation with StandardTime integration.

let package = Package(
    name: "swift-rfc-3339",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(
            name: "RFC 3339",
            targets: ["RFC 3339"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.7.0"),
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "RFC 3339",
            dependencies: [
                .product(name: "Standards", package: "swift-standards"),
                .product(name: "StandardTime", package: "swift-standards"),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986")
            ]
        ),
        .testTarget(
            name: "RFC 3339".tests,
            dependencies: [
                "RFC 3339",
                .product(name: "StandardsTestSupport", package: "swift-standards")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
