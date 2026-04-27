//
//  ObservabilityDemoView.swift
//  RemoteConfigStore
//
//  Demonstrates refresh visibility, update hooks, and store inspection state.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Observation
import RemoteConfigStore
import SwiftUI

struct ObservabilityDemoView: View {
    @State private var model = ObservabilityDemoViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                controls
                statePanel
                updateLog
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground).opacity(0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Observability")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            model.bootstrap()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Observability")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text("Watch refresh events arrive through the update stream and the lightweight update hook while inspecting cache state.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var controls: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Refresh Controls")
                    .font(.headline)

                HStack(spacing: 12) {
                    Button("Refresh") {
                        model.refresh()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isLoading)

                    Button("Inspect State") {
                        model.inspect()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isLoading)

                    Button("Reset Log") {
                        model.resetLog()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var statePanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Current State")
                    .font(.headline)

                if model.isLoading {
                    ProgressView("Refreshing...")
                }

                infoRow(title: "Status", value: model.statusMessage)
                infoRow(title: "Revision", value: "\(model.currentRevision)")
                infoRow(title: "Freshness", value: model.freshness)
                infoRow(title: "Refresh active", value: model.isRefreshInFlight ? "true" : "false")
                infoRow(title: "Stream events", value: "\(model.streamEventCount)")
                infoRow(title: "Hook events", value: "\(model.hookEventCount)")
            }
        }
    }

    private var updateLog: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Update Log")
                    .font(.headline)

                if model.events.isEmpty {
                    Text("Refresh to emit the first update event.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(model.events) { event in
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Text(event.source)
                                    .font(.subheadline.weight(.semibold))
                                    .frame(width: 72, alignment: .leading)

                                Text(event.summary)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 10)

                            if event.id != model.events.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}

@MainActor
@Observable
final class ObservabilityDemoViewModel {
    struct Event: Identifiable, Equatable {
        let id = UUID()
        let source: String
        let summary: String
    }

    private let fetcher = ObservabilityDemoFetcher()
    private var store: RemoteConfigStore?
    private var observationTask: Task<Void, Never>?

    var isLoading = false
    var statusMessage = "Refresh to emit update events."
    var currentRevision = 0
    var freshness = "No cache"
    var isRefreshInFlight = false
    var streamEventCount = 0
    var hookEventCount = 0
    var events: [Event] = []

    func bootstrap() {
        guard store == nil else {
            return
        }

        do {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("RemoteConfigStoreExample")
                .appendingPathComponent("ObservabilityDemoCache")
            let store = try RemoteConfigStore(
                fetcher: fetcher,
                cacheDirectory: directory,
                ttl: 30,
                onUpdate: { [weak self] update in
                    Task { @MainActor in
                        self?.recordHookUpdate(update)
                    }
                }
            )

            self.store = store
            observeUpdates(from: store)
            inspect()
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func refresh() {
        Task { [weak self] in
            guard let self else { return }
            await self.performRefresh()
        }
    }

    func inspect() {
        Task { [weak self] in
            guard let self else { return }
            await self.updateInspectionState()
        }
    }

    func resetLog() {
        events.removeAll()
        streamEventCount = 0
        hookEventCount = 0
    }

    private func performRefresh() async {
        guard let store else { return }

        isLoading = true
        statusMessage = "Refreshing..."
        await updateInspectionState()

        do {
            let result = try await store.refreshResult()
            currentRevision = result.snapshot.int(for: ObservabilityDemoKeys.revision)
            statusMessage = statusText(for: result)
            await updateInspectionState()
        } catch {
            statusMessage = error.localizedDescription
        }

        isLoading = false
        await updateInspectionState()
    }

    private func observeUpdates(from store: RemoteConfigStore) {
        observationTask?.cancel()
        observationTask = Task { [weak self] in
            let updates = await store.updates()
            for await update in updates {
                await self?.recordStreamUpdate(update)
            }
        }
    }

    private func recordStreamUpdate(_ update: RemoteConfigUpdate) {
        streamEventCount += 1
        appendEvent(source: "Stream", update: update)
    }

    private func recordHookUpdate(_ update: RemoteConfigUpdate) {
        hookEventCount += 1
        appendEvent(source: "Hook", update: update)
    }

    private func appendEvent(source: String, update: RemoteConfigUpdate) {
        let revision = update.snapshot.int(for: ObservabilityDemoKeys.revision)
        events.insert(
            Event(source: source, summary: "\(resultLabel(update.result)) revision \(revision)"),
            at: 0
        )
        events = Array(events.prefix(8))
    }

    private func updateInspectionState() async {
        guard let store else { return }

        do {
            let state = try await store.inspectionState()
            freshness = state.freshness.map(String.init(describing:)) ?? "No cache"
            isRefreshInFlight = state.isRefreshInFlight
            if let snapshot = state.snapshot {
                currentRevision = snapshot.int(for: ObservabilityDemoKeys.revision)
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func statusText(for result: RemoteConfigRefreshResult) -> String {
        "\(resultLabel(result)) revision \(result.snapshot.int(for: ObservabilityDemoKeys.revision))"
    }

    private func resultLabel(_ result: RemoteConfigRefreshResult) -> String {
        switch result {
        case .updated:
            return "Updated"
        case .unchanged:
            return "Unchanged"
        }
    }
}

private enum ObservabilityDemoKeys {
    static let revision = RemoteConfigKey<Int>("config_revision", defaultValue: 0)
}

private actor ObservabilityDemoFetcher: RemoteConfigFetcher {
    private var revision = 0

    func fetchSnapshot() async throws -> RemoteConfigSnapshot {
        revision += 1

        return RemoteConfigSnapshot(values: [
            "config_revision": .int(revision),
            "feature.observability": .bool(true)
        ])
    }
}

#Preview {
    NavigationStack {
        ObservabilityDemoView()
    }
}
