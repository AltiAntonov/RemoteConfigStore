//
//  HTTPRemoteConfigRequest.swift
//  RemoteConfigStore
//
//  Defines an HTTP request configuration for remote config fetching.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// Defines the HTTP request used by the built-in remote config fetcher.
public struct HTTPRemoteConfigRequest: Sendable, Equatable {
    /// The endpoint URL that returns the remote config payload.
    public let url: URL
    /// Additional HTTP headers applied to the request.
    public let headers: [String: String]
    /// The request timeout interval in seconds.
    public let timeoutInterval: TimeInterval?

    /// Creates an HTTP request configuration for remote config fetching.
    ///
    /// - Parameters:
    ///   - url: The endpoint URL that returns the config payload.
    ///   - headers: Additional HTTP headers applied to the request.
    ///   - timeoutInterval: The request timeout interval in seconds.
    public init(
        url: URL,
        headers: [String: String] = [:],
        timeoutInterval: TimeInterval? = nil
    ) {
        self.url = url
        self.headers = headers
        self.timeoutInterval = timeoutInterval
    }

    /// Builds a `URLRequest` from the current HTTP configuration.
    ///
    /// - Returns: A GET request configured with the current URL, headers, and timeout.
    public func urlRequest() throws -> URLRequest {
        try urlRequest(validationMetadata: nil)
    }

    /// Builds a `URLRequest` from the current HTTP configuration and optional validation metadata.
    ///
    /// - Parameter validationMetadata: Previously persisted HTTP validation values used for
    ///   conditional requests.
    /// - Returns: A GET request configured with the current URL, headers, timeout, and
    ///   conditional validation headers when available.
    public func urlRequest(
        validationMetadata: HTTPRemoteConfigValidationMetadata?
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        if
            request.value(forHTTPHeaderField: "If-None-Match") == nil,
            let entityTag = validationMetadata?.entityTag
        {
            request.setValue(entityTag, forHTTPHeaderField: "If-None-Match")
        }

        if
            request.value(forHTTPHeaderField: "If-Modified-Since") == nil,
            let lastModified = validationMetadata?.lastModified
        {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }

        if let timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }

        return request
    }
}
