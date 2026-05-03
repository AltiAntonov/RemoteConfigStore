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
        try await fetchSnapshot(validationMetadata: nil)
    }

    /// Fetches and decodes a remote configuration snapshot using optional HTTP validation metadata.
    ///
    /// - Parameter validationMetadata: Previously persisted validation metadata used to build a
    ///   conditional request.
    /// - Returns: A freshly fetched snapshot decoded from the HTTP response payload.
    /// - Throws: A transport, response, or payload decoding error.
    public func fetchSnapshot(
        validationMetadata: HTTPRemoteConfigValidationMetadata?
    ) async throws -> RemoteConfigSnapshot {
        let urlRequest = try request.urlRequest(validationMetadata: validationMetadata)
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPRemoteConfigFetcherError.invalidResponseType
        }

        if httpResponse.statusCode == 304 {
            throw HTTPRemoteConfigFetcherError.notModified(
                responseValidationMetadata(from: httpResponse) ?? validationMetadata
            )
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPRemoteConfigFetcherError.invalidResponseStatusCode(httpResponse.statusCode)
        }

        return try RemoteConfigSnapshot(
            values: decodeValues(from: data),
            httpValidationMetadata: responseValidationMetadata(from: httpResponse)
        )
    }

    private func decodeValues(from data: Data) throws -> [String: RemoteConfigValue] {
        guard
            let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw HTTPRemoteConfigFetcherError.invalidPayload
        }

        return try payload.mapValues(decodeValue)
    }

    private func decodeValue(_ rawValue: Any) throws -> RemoteConfigValue {
        switch rawValue {
        case let value as Bool:
            return .bool(value)
        case let value as Int:
            return .int(value)
        case let value as Double:
            return .double(value)
        case let value as String:
            return .string(value)
        case let value as [String: Any]:
            return try .object(value.mapValues(decodeValue))
        case let value as [Any]:
            return try .array(value.map(decodeValue))
        case is NSNull:
            return .null
        default:
            throw HTTPRemoteConfigFetcherError.invalidPayload
        }
    }

    private func responseValidationMetadata(
        from response: HTTPURLResponse
    ) -> HTTPRemoteConfigValidationMetadata? {
        let metadata = HTTPRemoteConfigValidationMetadata(
            entityTag: response.value(forHTTPHeaderField: "ETag"),
            lastModified: response.value(forHTTPHeaderField: "Last-Modified")
        )

        if metadata == HTTPRemoteConfigValidationMetadata() {
            return nil
        }

        return metadata
    }
}
