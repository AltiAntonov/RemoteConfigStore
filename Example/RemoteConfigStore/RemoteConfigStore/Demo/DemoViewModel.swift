//
//  DemoViewModel.swift
//  RemoteConfigStore
//
//  Drives the example screen and surfaces cache-versus-refresh behavior.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Observation
import RemoteConfigStore

@MainActor
@Observable
final class DemoViewModel {
    struct DisplayRow: Identifiable, Equatable {
        let id: String
        let title: String
        let value: String
    }

    private let fetcher = DemoRemoteConfigFetcher()
    private var store: RemoteConfigStore?
    private var backgroundSyncTask: Task<Void, Never>?
    private var bootstrapTask: Task<Void, Never>?

    var selectedPolicy: ReadPolicy = .immediate
    var isBootstrapped = false
    var isLoading = false
    var statusMessage = "Load a policy to see the cache behavior."
    var errorMessage: String?
    var displayedSnapshot: RemoteConfigSnapshot?
    var currentRevision = 1
    var remoteRevision = 1
    var fetchCount = 0
    var lastLoadedAt: Date?

    /// Prepares the demo store and performs the first load only once.
    func bootstrap() {
        guard bootstrapTask == nil else {
            return
        }

        bootstrapTask = Task { [weak self] in
            guard let self else { return }
            defer { self.bootstrapTask = nil }

            do {
                try await self.prepareStoreIfNeeded()
                self.isBootstrapped = true
                try await self.load(using: self.selectedPolicy)
            } catch {
                self.errorMessage = error.localizedDescription
                self.statusMessage = "The demo store could not start."
            }
        }
    }

    /// Selects a read policy without loading data yet.
    func selectPolicy(_ policy: ReadPolicy) {
        selectedPolicy = policy
        statusMessage = "Selected \(Self.policyLabel(for: policy))."
        errorMessage = nil
    }

    /// Loads the current config using the selected policy.
    func loadSelectedPolicy() {
        Task { [weak self] in
            guard let self else { return }
            try await self.load(using: self.selectedPolicy)
        }
    }

    /// Forces an immediate refresh from the simulated backend.
    func refreshNow() {
        Task { [weak self] in
            guard let self else { return }
            await self.performManualRefresh()
        }
    }

    /// Advances the remote revision so the next fetch returns newer values.
    func advanceRemoteRevision() {
        Task { [weak self] in
            guard let self else { return }
            await self.fetcher.advanceRevision()
            await self.syncBackendState()
            self.statusMessage = "Remote revision advanced. Load again to compare cache and refresh."
        }
    }

    private func performManualRefresh() async {
        do {
            try await prepareStoreIfNeeded()
            isLoading = true
            errorMessage = nil

            let snapshot = try await store?.refresh() ?? RemoteConfigSnapshot(values: [:])
            await syncBackendState()
            apply(snapshot: snapshot, policy: .refreshBeforeReturning, source: "Manual refresh")
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Manual refresh failed."
        }

        isLoading = false
    }

    private func load(using policy: ReadPolicy) async throws {
        try await prepareStoreIfNeeded()
        backgroundSyncTask?.cancel()
        backgroundSyncTask = nil

        isLoading = true
        errorMessage = nil

        do {
            let snapshot = try await store?.snapshot(using: policy) ?? RemoteConfigSnapshot(values: [:])
            await syncBackendState()
            apply(snapshot: snapshot, policy: policy, source: Self.policyLabel(for: policy))

            if policy == .immediateWithBackgroundRefresh {
                scheduleBackgroundSync()
            }
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Load failed for \(Self.policyLabel(for: policy))."
            throw error
        }

        isLoading = false
    }

    private func apply(snapshot: RemoteConfigSnapshot, policy: ReadPolicy, source: String) {
        displayedSnapshot = snapshot
        lastLoadedAt = Date()

        let servingMode: String
        switch policy {
        case .immediate:
            servingMode = remoteRevision > currentRevision ? "cache-first" : "fresh"
        case .refreshBeforeReturning:
            servingMode = "refresh-first"
        case .immediateWithBackgroundRefresh:
            servingMode = remoteRevision > currentRevision ? "background refresh pending" : "background refresh complete"
        }

        currentRevision = snapshot.values["config_revision"]?.intValue ?? currentRevision
        statusMessage = "\(source) returned revision \(currentRevision) using \(servingMode)."
    }

    private func scheduleBackgroundSync() {
        backgroundSyncTask = Task { [weak self] in
            guard let self else { return }

            try? await Task.sleep(nanoseconds: 850_000_000)
            await self.syncSnapshotFromCache()
        }
    }

    private func syncSnapshotFromCache() async {
        do {
            if let snapshot = try await store?.cachedSnapshot() {
                displayedSnapshot = snapshot
                currentRevision = snapshot.values["config_revision"]?.intValue ?? currentRevision
                lastLoadedAt = Date()
                statusMessage = "Background refresh updated the cache to revision \(currentRevision)."
            }
        } catch {
            statusMessage = "Background refresh did not update the cache yet."
        }

        await syncBackendState()
    }

    private func prepareStoreIfNeeded() async throws {
        if store != nil {
            return
        }

        let cacheDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RemoteConfigStoreExample")
            .appendingPathComponent("DemoCache")

        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        store = try RemoteConfigStore(
            fetcher: fetcher,
            cacheDirectory: cacheDirectory,
            ttl: 2,
            maxStaleAge: 30
        )
    }

    private func syncBackendState() async {
        remoteRevision = await fetcher.currentRevision()
        fetchCount = await fetcher.currentFetchCount()
    }

    private static func policyLabel(for policy: ReadPolicy) -> String {
        switch policy {
        case .immediate:
            return "Immediate"
        case .refreshBeforeReturning:
            return "Refresh before returning"
        case .immediateWithBackgroundRefresh:
            return "Immediate with background refresh"
        }
    }

    var displayedRows: [DisplayRow] {
        guard let snapshot = displayedSnapshot else {
            return []
        }

        return [
            DisplayRow(id: "config_revision", title: "config_revision", value: snapshot.values["config_revision"].map(describe(_:)) ?? "missing"),
            DisplayRow(id: "feature.new_ui", title: "feature.new_ui", value: snapshot.values["feature.new_ui"].map(describe(_:)) ?? "missing"),
            DisplayRow(id: "welcome_message", title: "welcome_message", value: snapshot.values["welcome_message"].map(describe(_:)) ?? "missing"),
            DisplayRow(id: "request_timeout_ms", title: "request_timeout_ms", value: snapshot.values["request_timeout_ms"].map(describe(_:)) ?? "missing"),
            DisplayRow(id: "rollout_fraction", title: "rollout_fraction", value: snapshot.values["rollout_fraction"].map(describe(_:)) ?? "missing")
        ]
    }

    private func describe(_ value: RemoteConfigValue) -> String {
        switch value {
        case let .bool(value):
            return value ? "true" : "false"
        case let .int(value):
            return "\(value)"
        case let .double(value):
            return String(format: "%.2f", value)
        case let .string(value):
            return value
        }
    }
}
