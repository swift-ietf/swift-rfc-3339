// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-3339",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "RFC 3339", targets: ["RFC 3339"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-atoms/swift-standard-library-extensions.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-binary.git",
            branch: "main", traits: ["Serializer"]),
        .package(
            url: "https://github.com/swift-atoms/swift-time.git",
            branch: "main"
        ),
        .package(url: "https://github.com/swift-atoms/swift-ascii.git", branch: "main", traits: ["Parser", "Serializer"]),
        .package(url: "https://github.com/swift-atoms/swift-calendar.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-calendar-gregorian.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "RFC 3339",
            dependencies: [
                .product(
                    name: "Standard Library Extensions",
                    package: "swift-standard-library-extensions"
                ),
                .product(name: "Binary", package: "swift-binary"),
                .product(name: "Time", package: "swift-time"),
                .product(name: "ASCII", package: "swift-ascii"),
                .product(name: "Calendar", package: "swift-calendar"),
                .product(name: "Calendar Gregorian", package: "swift-calendar-gregorian"),
            ]
        ),
        .testTarget(
            name: "RFC 3339 Tests",
            dependencies: [
                .target(name: "RFC 3339"),
                .product(name: "Binary", package: "swift-binary"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
