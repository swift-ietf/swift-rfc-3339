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
            url: "https://github.com/swift-primitives/swift-ascii-serializer-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-binary-serializer-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-ascii-parser-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-standard-library-extensions.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-binary-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-time-primitives.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "RFC 3339",
            dependencies: [
                .product(
                    name: "ASCII Serializer Primitives",
                    package: "swift-ascii-serializer-primitives"
                ),
                .product(
                    name: "Binary Serializable Primitives",
                    package: "swift-binary-serializer-primitives"
                ),
                .product(
                    name: "Parseable ASCII Primitives",
                    package: "swift-ascii-parser-primitives"
                ),
                .product(
                    name: "Standard Library Extensions",
                    package: "swift-standard-library-extensions"
                ),
                .product(name: "Binary Primitives", package: "swift-binary-primitives"),
                .product(name: "Time Primitives", package: "swift-time-primitives"),
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
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
