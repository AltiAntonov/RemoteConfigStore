//
//  HTTPRemoteConfigRequestTests.swift
//  RemoteConfigStoreTests
//
//  Verifies HTTP request configuration for the built-in fetcher.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Testing
@testable import RemoteConfigStore

struct HTTPRemoteConfigRequestTests {
    @Test
    func requestBuildsGETURLRequestWithHeadersAndTimeout() throws {
        let url = try #require(URL(string: "https://example.com/config"))
        let request = HTTPRemoteConfigRequest(
            url: url,
            headers: [
                "Authorization": "Bearer token",
                "X-Client": "RemoteConfigStoreExample"
            ],
            timeoutInterval: 12
        )

        let urlRequest = try request.urlRequest()

        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.url == url)
        #expect(urlRequest.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(urlRequest.value(forHTTPHeaderField: "X-Client") == "RemoteConfigStoreExample")
        #expect(urlRequest.timeoutInterval == 12)
    }
}
