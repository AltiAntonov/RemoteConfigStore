//
//  StructuredPayloadDemoView.swift
//  RemoteConfigStore
//
//  Demonstrates decoding nested config into consumer-defined models.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation
import Observation
import RemoteConfigStore
import SwiftUI

struct StructuredPayloadDemoView: View {
    @State private var model = StructuredPayloadDemoViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                controls
                decodedPanel
                rawSnapshotPanel
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
        .navigationTitle("Structured Payloads")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            model.bootstrap()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Structured Payloads")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text("Decode one nested remote config key into an app-owned `Decodable` model while keeping raw snapshot data available for inspection.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var controls: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Payload Controls")
                    .font(.headline)

                Text("Load a valid payload first, then switch to a malformed payload to see structured decoding fail without hiding the raw cached value.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button("Load Structured Config") {
                        model.load()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isLoading)

                    Button(model.usesMalformedPayload ? "Use Valid Payload" : "Use Malformed Payload") {
                        model.togglePayloadShape()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isLoading)

                    Button("Advance Revision") {
                        model.advanceRevision()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isLoading)
                }

                infoRow(title: "Status", value: model.statusMessage)
                infoRow(title: "Payload shape", value: model.usesMalformedPayload ? "Malformed title value" : "Valid nested object")
                infoRow(title: "Remote revision", value: "\(model.remoteRevision)")
                infoRow(title: "Fetch count", value: "\(model.fetchCount)")
            }
        }
    }

    private var decodedPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Decoded Model")
                    .font(.headline)

                Text("This panel is populated through `store.decodedValue(PaywallConfig.self, for: \"paywall\")`.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if model.isLoading {
                    ProgressView("Loading...")
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }

                if let paywall = model.paywall {
                    VStack(spacing: 0) {
                        infoRow(title: "Title", value: paywall.title)
                        Divider()
                        infoRow(title: "Enabled", value: paywall.enabled ? "true" : "false")
                        Divider()
                        infoRow(title: "CTA", value: paywall.callToAction)
                        Divider()
                        infoRow(title: "Tiers", value: paywall.tiers.joined(separator: ", "))
                        Divider()
                        infoRow(title: "Max trials", value: "\(paywall.limits.maxTrialStarts)")
                    }
                } else if model.errorMessage == nil {
                    Text("Load structured config to decode the paywall model.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var rawSnapshotPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Raw Snapshot")
                    .font(.headline)

                Text("The raw value remains inspectable even when the requested model cannot be decoded.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if model.rawRows.isEmpty {
                    Text("No snapshot loaded yet.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(model.rawRows) { row in
                            infoRow(title: row.title, value: row.value)

                            if row.id != model.rawRows.last?.id {
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
        .padding(.vertical, 4)
    }
}

@MainActor
@Observable
final class StructuredPayloadDemoViewModel {
    struct Row: Identifiable, Equatable {
        let id: String
        let title: String
        let value: String
    }

    private let fetcher = StructuredPayloadDemoFetcher()
    private var store: RemoteConfigStore?

    var isLoading = false
    var statusMessage = "Load a nested payload."
    var errorMessage: String?
    var paywall: PaywallConfig?
    var rawRows: [Row] = []
    var remoteRevision = 1
    var fetchCount = 0
    var usesMalformedPayload = false

    func bootstrap() {
        guard store == nil else {
            return
        }

        do {
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("RemoteConfigStoreExample")
                .appendingPathComponent("StructuredPayloadDemoCache")
            try? FileManager.default.removeItem(at: directory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            store = try RemoteConfigStore(
                fetcher: fetcher,
                cacheDirectory: directory,
                ttl: 60
            )
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func load() {
        Task { [weak self] in
            guard let self else { return }
            await self.performLoad()
        }
    }

    func togglePayloadShape() {
        Task { [weak self] in
            guard let self else { return }
            usesMalformedPayload.toggle()
            await fetcher.setMalformedPayload(usesMalformedPayload)
            statusMessage = usesMalformedPayload
                ? "Next load will return a malformed title value."
                : "Next load will return a valid nested object."
        }
    }

    func advanceRevision() {
        Task { [weak self] in
            guard let self else { return }
            await fetcher.advanceRevision()
            remoteRevision = await fetcher.currentRevision()
            statusMessage = "Remote revision advanced. Load again to refresh the structured payload."
        }
    }

    private func performLoad() async {
        guard let store else { return }

        isLoading = true
        errorMessage = nil
        paywall = nil
        statusMessage = "Loading structured config..."

        do {
            let decoded = try await store.decodedValue(
                PaywallConfig.self,
                for: "paywall",
                using: .refreshBeforeReturning
            )
            paywall = decoded
            statusMessage = "Decoded paywall revision \(decoded.revision)."
        } catch {
            errorMessage = describe(error)
            statusMessage = "Structured decoding failed."
        }

        await refreshRawRows()
        remoteRevision = await fetcher.currentRevision()
        fetchCount = await fetcher.currentFetchCount()
        isLoading = false
    }

    private func refreshRawRows() async {
        guard let store else { return }

        do {
            let snapshot = try await store.cachedSnapshot()
            rawRows = [
                Row(id: "paywall", title: "paywall", value: describe(snapshot.value(for: "paywall"))),
                Row(id: "revision", title: "revision", value: snapshot.value(for: "paywall")?.objectValue?["revision"]?.intValue.map(String.init) ?? "missing"),
                Row(id: "title", title: "title", value: describe(snapshot.value(for: "paywall")?.objectValue?["title"])),
                Row(id: "tiers", title: "tiers", value: describe(snapshot.value(for: "paywall")?.objectValue?["tiers"]))
            ]
        } catch {
            rawRows = []
        }
    }

    private func describe(_ error: Error) -> String {
        switch error {
        case let error as RemoteConfigDecodingError:
            return "\(error)"
        default:
            return error.localizedDescription
        }
    }

    private func describe(_ value: RemoteConfigValue?) -> String {
        guard let value else {
            return "missing"
        }

        switch value {
        case let .bool(value):
            return value ? "true" : "false"
        case let .int(value):
            return "\(value)"
        case let .double(value):
            return String(format: "%.2f", value)
        case let .string(value):
            return value
        case let .object(value):
            return "object(\(value.count) fields)"
        case let .array(value):
            return "array(\(value.count) items)"
        case .null:
            return "null"
        }
    }
}

nonisolated struct PaywallConfig: Decodable, Equatable, Sendable {
    nonisolated struct Limits: Decodable, Equatable, Sendable {
        let maxTrialStarts: Int
    }

    let revision: Int
    let title: String
    let enabled: Bool
    let callToAction: String
    let tiers: [String]
    let limits: Limits
}

actor StructuredPayloadDemoFetcher: RemoteConfigFetcher {
    private var revision = 1
    private var fetchCount = 0
    private var usesMalformedPayload = false

    func advanceRevision() {
        revision += 1
    }

    func setMalformedPayload(_ usesMalformedPayload: Bool) {
        self.usesMalformedPayload = usesMalformedPayload
        revision += 1
    }

    func currentRevision() -> Int {
        revision
    }

    func currentFetchCount() -> Int {
        fetchCount
    }

    func fetchSnapshot() async throws -> RemoteConfigSnapshot {
        fetchCount += 1
        try await Task.sleep(nanoseconds: 450_000_000)

        return RemoteConfigSnapshot(values: [
            "paywall": makePaywallValue()
        ])
    }

    private func makePaywallValue() -> RemoteConfigValue {
        .object([
            "revision": .int(revision),
            "title": usesMalformedPayload ? .int(revision) : .string(revision >= 2 ? "Go Pro Today" : "Upgrade to Pro"),
            "enabled": .bool(revision >= 1),
            "callToAction": .string(revision >= 2 ? "Start trial" : "Learn more"),
            "tiers": .array([
                .string("monthly"),
                .string("yearly")
            ]),
            "limits": .object([
                "maxTrialStarts": .int(revision >= 3 ? 2 : 1)
            ]),
            "subtitle": .null
        ])
    }
}

#Preview {
    NavigationStack {
        StructuredPayloadDemoView()
    }
}
