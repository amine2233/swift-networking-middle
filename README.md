# Network Middle

The framework use to request Network API.

## Installation

Add this package to your Package.swift as dependency and to your target.

```swift
dependencies: [
    .package(
        url: "https://github.com/amine2233/swift-networking-middle.git",
        from: "1.0.0"
    )
],
targets: [
    .target(name: "App", dependencies: [
        .product(name: "NetworkingMiddle", package: "networking-middle"),
    ]),
    .testTarget(name: "AppTests", dependencies: [
        .product(name: "NetworkingMiddleTesting", package: "networking-middle"),
        .product(name: "NetworkingMiddleMocking", package: "networking-middle")
    ])
]
```

Import in your code

```swift
import NetworkingMiddle
```

Import in your tests code

```swift
import NetworkingMiddleTesting
import NetworkingMiddleMocking
```
