//
//  HTTPRemoteConfigFetcherError.swift
//  RemoteConfigStore
//
//  Defines errors thrown by the built-in HTTP fetcher.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Describes failures thrown by the built-in HTTP remote config fetcher.
public enum HTTPRemoteConfigFetcherError: Error, Sendable, Equatable {
    /// The server returned an unexpected HTTP status code.
    case invalidResponseStatusCode(Int)
    /// The transport response was not an `HTTPURLResponse`.
    case invalidResponseType
    /// The response payload could not be decoded into supported primitive values.
    case invalidPayload
}
