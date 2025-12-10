// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-3339",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: "RFC 3339", targets: ["RFC 3339"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986", from: "0.6.3"),
        .package(url: "https://github.com/swift-standards/swift-standards", from: "0.10.0"),
    ],
    targets: [
        .target(
            name: "RFC 3339",
            dependencies: [
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986"),
                .product(name: "Standards", package: "swift-standards"),
                .product(name: "StandardTime", package: "swift-standards"),
            ]
        ),
        .testTarget(
            name: "RFC 3339".tests,
            dependencies: ["RFC 3339"]
        )
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    target.swiftSettings = (target.swiftSettings ?? []) + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
