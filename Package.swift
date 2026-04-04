// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RemoteConfigStore",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "RemoteConfigStore",
            targets: ["RemoteConfigStore"]
        )
    ],
    targets: [
        .target(
            name: "RemoteConfigStore"
        ),
        .testTarget(
            name: "RemoteConfigStoreTests",
            dependencies: ["RemoteConfigStore"]
        )
    ]
)
