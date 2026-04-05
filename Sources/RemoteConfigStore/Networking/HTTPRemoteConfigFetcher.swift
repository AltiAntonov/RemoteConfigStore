//
//  HTTPRemoteConfigFetcher.swift
//  RemoteConfigStore
//
//  Fetches remote configuration snapshots using URLSession.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

/// A `URLSession`-backed fetcher for remote configuration snapshots.
public struct HTTPRemoteConfigFetcher: RemoteConfigFetcher, Sendable {
    /// The request configuration used for fetching remote config.
    public let request: HTTPRemoteConfigRequest
    private let session: URLSession

    /// Creates a built-in HTTP fetcher for remote config.
    ///
    /// - Parameters:
    ///   - request: The HTTP request configuration for the config endpoint.
    ///   - session: The session used to perform network requests.
    public init(
        request: HTTPRemoteConfigRequest,
        session: URLSession = .shared
    ) {
        self.request = request
        self.session = session
    }

    /// Fetches and decodes a remote configuration snapshot from the configured HTTP endpoint.
    ///
    /// - Returns: A freshly fetched snapshot decoded from the HTTP response payload.
    /// - Throws: A transport, response, or payload decoding error.
    public func fetchSnapshot() async throws -> RemoteConfigSnapshot {
        let urlRequest = try request.urlRequest()
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPRemoteConfigFetcherError.invalidResponseType
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPRemoteConfigFetcherError.invalidResponseStatusCode(httpResponse.statusCode)
        }

        return try RemoteConfigSnapshot(values: decodeValues(from: data))
    }

    private func decodeValues(from data: Data) throws -> [String: RemoteConfigValue] {
        guard
            let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw HTTPRemoteConfigFetcherError.invalidPayload
        }

        var values: [String: RemoteConfigValue] = [:]
        for (key, rawValue) in payload {
            switch rawValue {
            case let value as Bool:
                values[key] = .bool(value)
            case let value as Int:
                values[key] = .int(value)
            case let value as Double:
                values[key] = .double(value)
            case let value as String:
                values[key] = .string(value)
            default:
                throw HTTPRemoteConfigFetcherError.invalidPayload
            }
        }

        return values
    }
}
