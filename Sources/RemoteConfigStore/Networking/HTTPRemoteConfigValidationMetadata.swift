//
//  HTTPRemoteConfigValidationMetadata.swift
//  RemoteConfigStore
//
//  Captures persisted HTTP validation values for conditional config requests.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Captures HTTP response metadata used for conditional remote config requests.
public struct HTTPRemoteConfigValidationMetadata: Codable, Sendable, Equatable {
    /// The entity tag returned by the server for the fetched payload, if one exists.
    public let entityTag: String?

    /// The `Last-Modified` value returned by the server for the fetched payload, if one exists.
    public let lastModified: String?

    /// Creates HTTP validation metadata for a fetched remote config response.
    ///
    /// - Parameters:
    ///   - entityTag: The response `ETag` value, if one exists.
    ///   - lastModified: The response `Last-Modified` value, if one exists.
    public init(
        entityTag: String? = nil,
        lastModified: String? = nil
    ) {
        self.entityTag = entityTag
        self.lastModified = lastModified
    }
}
