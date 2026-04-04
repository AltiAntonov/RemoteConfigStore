//
//  FeatureFlagsDemoView.swift
//  RemoteConfigStore
//
//  Demonstrates a feature-flags style remote config workflow.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import SwiftUI
import RemoteConfigStore

struct FeatureFlagsDemoView: View {
    @State private var model = DemoViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                controlPanel
                statePanel
                typedAccessorsPanel
                snapshotPanel
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
        .navigationTitle("Feature Flags")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            model.bootstrap()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Feature Flags")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text("A realistic feature-flag scenario with typed keys, cache-first policies, and a remote revision that can move ahead of the local cache.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var controlPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                Text("Read Policy")
                    .font(.headline)

                VStack(spacing: 10) {
                    policyButton(title: "Immediate", policy: .immediate)
                    policyButton(title: "Refresh Before Returning", policy: .refreshBeforeReturning)
                    policyButton(title: "Immediate + Background Refresh", policy: .immediateWithBackgroundRefresh)
                }

                HStack(spacing: 12) {
                    Button("Load Selected Policy") {
                        model.loadSelectedPolicy()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isLoading)

                    Button("Manual Refresh") {
                        model.refreshNow()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isLoading)

                    Button("Advance Remote Revision") {
                        model.advanceRemoteRevision()
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.isLoading)
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
                    ProgressView("Loading...")
                        .padding(.vertical, 4)
                }

                infoRow(title: "Status", value: model.statusMessage)
                infoRow(title: "Selected policy", value: policyLabel(model.selectedPolicy))
                infoRow(title: "Displayed revision", value: "\(model.currentRevision)")
                infoRow(title: "Remote revision", value: "\(model.remoteRevision)")
                infoRow(title: "Fetch count", value: "\(model.fetchCount)")
                infoRow(title: "Last updated", value: model.lastLoadedAt.map { Self.dateFormatter.string(from: $0) } ?? "Not loaded yet")

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var typedAccessorsPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Typed Accessors")
                    .font(.headline)

                Text("These values are resolved through `RemoteConfigKey` definitions and the store convenience APIs such as `bool(for:)` and `string(for:)`.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if model.displayedRows.isEmpty {
                    Text("Load a policy to resolve typed values.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(model.displayedRows) { row in
                            snapshotRow(row)

                            if row.id != model.displayedRows.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private var snapshotPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Raw Cached Snapshot")
                    .font(.headline)

                Text("This panel shows the underlying cached payload so you can compare it with the consumer-facing typed accessors above.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if model.snapshotRows.isEmpty {
                    Text("No snapshot loaded yet.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(model.snapshotRows) { row in
                            snapshotRow(row)

                            if row.id != model.snapshotRows.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                Text(model.remoteRevision > model.currentRevision ? "The backend has moved ahead of the shown cache. Use a policy load or refresh to catch up." : "The cache matches the latest backend revision.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }

    private func policyButton(title: String, policy: ReadPolicy) -> some View {
        Button {
            model.selectPolicy(policy)
        } label: {
            HStack {
                Text(title)
                Spacer()
                if model.selectedPolicy == policy {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .font(.body.weight(model.selectedPolicy == policy ? .semibold : .regular))
        }
        .buttonStyle(.plain)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(model.selectedPolicy == policy ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    private func snapshotRow(_ row: DemoViewModel.DisplayRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(row.title)
                .font(.subheadline.weight(.semibold))
                .frame(width: 150, alignment: .leading)

            Text(row.value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.vertical, 10)
    }

    private func policyLabel(_ policy: ReadPolicy) -> String {
        switch policy {
        case .immediate:
            return "Immediate"
        case .refreshBeforeReturning:
            return "Refresh before returning"
        case .immediateWithBackgroundRefresh:
            return "Immediate + background refresh"
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

#Preview {
    NavigationStack {
        FeatureFlagsDemoView()
    }
}
