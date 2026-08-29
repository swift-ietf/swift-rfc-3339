// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-3339",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
    ],
    products: [
        .library(name: "RFC 3339", targets: ["RFC 3339"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-molecules/swift-ascii-serializer.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-binary-serializer.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-ascii-parser.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-atoms/swift-standard-library-extensions.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-binary.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-molecules/swift-time.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "RFC 3339",
            dependencies: [
                .product(
                    name: "ASCII Serializer",
                    package: "swift-ascii-serializer"
                ),
                .product(
                    name: "Binary Serializable",
                    package: "swift-binary-serializer"
                ),
                .product(
                    name: "Parseable ASCII",
                    package: "swift-ascii-parser"
                ),
                .product(
                    name: "Standard Library Extensions",
                    package: "swift-standard-library-extensions"
                ),
                .product(name: "Binary", package: "swift-binary"),
                .product(name: "Time", package: "swift-time"),
            ]
        ),
        .testTarget(
            name: "RFC 3339 Tests",
            dependencies: [
                "RFC 3339"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
}

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
