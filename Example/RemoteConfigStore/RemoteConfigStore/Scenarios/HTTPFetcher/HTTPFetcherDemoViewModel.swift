//
//  HTTPFetcherDemoViewModel.swift
//  RemoteConfigStore
//
//  Drives the HTTP fetcher example scenario.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Observation
import RemoteConfigStore

@MainActor
@Observable
final class HTTPFetcherDemoViewModel {
    struct Row: Identifiable, Equatable {
        let id: String
        let title: String
        let value: String
    }

    enum DemoKeys {
        static let revision = RemoteConfigKey<Int>("config_revision", defaultValue: 0)
        static let enableHTTPConfig = RemoteConfigKey<Bool>("feature.http_config", defaultValue: false)
        static let apiHost = RemoteConfigKey<String>("api_host", defaultValue: "unknown")
        static let requestTimeout = RemoteConfigKey<Int>("request_timeout_ms", defaultValue: 0)
    }

    private let endpointURL = URL(string: "https://example.com/remote-config.json")!
    private let protocolHandler = HTTPDemoURLProtocolHandler()
    private var store: RemoteConfigStore?

    var isLoading = false
    var statusMessage = "Load from the mocked HTTP endpoint."
    var errorMessage: String?
    var fetchCount = 0
    var serverRevision = 1
    var lastLoadedAt: Date?
    var lastRefreshResult = "No refresh yet"
    var rows: [Row] = []

    var endpoint: String {
        endpointURL.absoluteString
    }

    func bootstrap() {
        guard store == nil else {
            return
        }

        serverRevision = protocolHandler.currentRevision
        fetchCount = protocolHandler.fetchCount
        store = try? makeStore()
    }

    func load() {
        Task { [weak self] in
            guard let self else { return }
            await self.performLoad()
        }
    }

    func advanceRevision() {
        protocolHandler.advanceRevision()
        serverRevision = protocolHandler.currentRevision
        statusMessage = "Mock server revision advanced. Load again to fetch the new payload."
    }

    private func performLoad() async {
        do {
            if store == nil {
                store = try makeStore()
            }

            guard let store else { return }
            isLoading = true
            errorMessage = nil

            let result = try await store.refreshResult()
            let snapshot = result.snapshot
            lastLoadedAt = Date()
            fetchCount = protocolHandler.fetchCount
            serverRevision = protocolHandler.currentRevision
            lastRefreshResult = switch result {
            case .updated:
                "Updated"
            case .unchanged:
                "Unchanged"
            }
            rows = [
                Row(id: "config_revision", title: "config_revision", value: "\(snapshot.int(for: DemoKeys.revision))"),
                Row(id: "feature.http_config", title: "feature.http_config", value: snapshot.bool(for: DemoKeys.enableHTTPConfig) ? "true" : "false"),
                Row(id: "api_host", title: "api_host", value: snapshot.string(for: DemoKeys.apiHost)),
                Row(id: "request_timeout_ms", title: "request_timeout_ms", value: "\(snapshot.int(for: DemoKeys.requestTimeout))")
            ]
            statusMessage = "Loaded revision \(snapshot.int(for: DemoKeys.revision)) from the mocked HTTP endpoint."
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "HTTP load failed."
        }

        isLoading = false
    }

    private func makeStore() throws -> RemoteConfigStore {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [HTTPDemoURLProtocol.self]
        HTTPDemoURLProtocol.setHandler(protocolHandler)

        let session = URLSession(configuration: configuration)
        let cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemoteConfigStoreExample")
            .appendingPathComponent("HTTPDemoCache")

        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        return try RemoteConfigStore(
            request: HTTPRemoteConfigRequest(
                url: endpointURL,
                headers: ["Authorization": "Bearer demo-token"],
                timeoutInterval: 8
            ),
            cacheDirectory: cacheDirectory,
            ttl: 60,
            session: session
        )
    }
}

private final class HTTPDemoURLProtocolHandler {
    private(set) var fetchCount = 0
    private(set) var currentRevision = 1

    func advanceRevision() {
        currentRevision += 1
    }

    func handle(_ request: URLRequest) throws -> (HTTPURLResponse, Data) {
        fetchCount += 1

        let payload = [
            "config_revision": currentRevision,
            "feature.http_config": currentRevision >= 2,
            "api_host": currentRevision >= 2 ? "api-v2.example.com" : "api.example.com",
            "request_timeout_ms": currentRevision >= 2 ? 800 : 1200
        ] as [String: Any]

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = try JSONSerialization.data(withJSONObject: payload)
        return (response, data)
    }
}

private final class HTTPDemoURLProtocol: URLProtocol, @unchecked Sendable {
    private static let handlerLock = NSLock()
    private static var currentHandler: HTTPDemoURLProtocolHandler?

    static func setHandler(_ handler: HTTPDemoURLProtocolHandler) {
        handlerLock.lock()
        currentHandler = handler
        handlerLock.unlock()
    }

    private static func handler() -> HTTPDemoURLProtocolHandler? {
        handlerLock.lock()
        defer { handlerLock.unlock() }
        return currentHandler
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler() else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler.handle(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
