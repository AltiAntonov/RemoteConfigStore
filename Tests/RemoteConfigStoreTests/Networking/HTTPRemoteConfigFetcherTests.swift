//
//  HTTPRemoteConfigFetcherTests.swift
//  RemoteConfigStoreTests
//
//  Verifies the built-in URLSession-backed remote config fetcher.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Testing
@testable import RemoteConfigStore

@Suite(.serialized)
struct HTTPRemoteConfigFetcherTests {
    @Test
    func fetcherDecodesPrimitiveJSONPayloadIntoSnapshot() async throws {
        MockURLProtocol.setRequestHandler { request in
            #expect(request.url?.absoluteString == "https://example.com/config")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token")

            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let data = Data(#"{"feature.new_ui":true,"request_timeout_ms":1200,"rollout_fraction":0.25,"welcome_message":"Hello"}"#.utf8)
            return (response, data)
        }

        defer { MockURLProtocol.setRequestHandler(nil) }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockedSession = URLSession(configuration: configuration)

        let fetcher = HTTPRemoteConfigFetcher(
            request: HTTPRemoteConfigRequest(
                url: try #require(URL(string: "https://example.com/config")),
                headers: ["Authorization": "Bearer token"]
            ),
            session: mockedSession
        )

        let snapshot = try await fetcher.fetchSnapshot()

        #expect(snapshot.bool(for: RemoteConfigKey("feature.new_ui", defaultValue: false)) == true)
        #expect(snapshot.int(for: RemoteConfigKey("request_timeout_ms", defaultValue: 0)) == 1200)
        #expect(snapshot.double(for: RemoteConfigKey("rollout_fraction", defaultValue: 0)) == 0.25)
        #expect(snapshot.string(for: RemoteConfigKey("welcome_message", defaultValue: "")) == "Hello")
    }

    @Test
    func fetcherThrowsForUnexpectedStatusCode() async throws {
        MockURLProtocol.setRequestHandler { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 500,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        defer { MockURLProtocol.setRequestHandler(nil) }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let mockedSession = URLSession(configuration: configuration)

        let fetcher = HTTPRemoteConfigFetcher(
            request: HTTPRemoteConfigRequest(
                url: try #require(URL(string: "https://example.com/config"))
            ),
            session: mockedSession
        )

        await #expect(throws: HTTPRemoteConfigFetcherError.invalidResponseStatusCode(500)) {
            try await fetcher.fetchSnapshot()
        }
    }
}
