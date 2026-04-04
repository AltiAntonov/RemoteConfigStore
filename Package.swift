//
//  Package.swift
//  RemoteConfigStore
//
//  Declares the RemoteConfigStore package and its targets.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RemoteConfigStore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
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
