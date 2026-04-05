//
//  MockURLProtocol.swift
//  RemoteConfigStoreTests
//
//  Intercepts URLSession requests for HTTP fetcher tests.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    private static let storage = HandlerStorage()

    static func setRequestHandler(
        _ handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?
    ) {
        storage.handler = handler
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.storage.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class HandlerStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var _handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _handler
        }
        set {
            lock.lock()
            _handler = newValue
            lock.unlock()
        }
    }
}
