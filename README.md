# swift-rfc-3339

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Parsing and formatting of RFC 3339 Internet date-time timestamps.

## Standard Reference

- **RFC**: 3339
- **Title**: Date and Time on the Internet: Timestamps

## Installation

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-3339.git", from: "0.5.5")
]
```

Add the product to a target that needs it:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 3339", package: "swift-rfc-3339")
    ]
)
```

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
