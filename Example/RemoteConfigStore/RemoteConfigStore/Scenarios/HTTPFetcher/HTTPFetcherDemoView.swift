//
//  HTTPFetcherDemoView.swift
//  RemoteConfigStore
//
//  Demonstrates the built-in HTTP fetcher using a mocked URLSession endpoint.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import SwiftUI
import RemoteConfigStore

struct HTTPFetcherDemoView: View {
    @State private var model = HTTPFetcherDemoViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                requestPanel
                statePanel
                valuesPanel
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
        .navigationTitle("HTTP Fetcher")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            model.bootstrap()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HTTP Fetcher")
                .font(.system(size: 30, weight: .bold, design: .rounded))

            Text("This scenario uses the built-in `HTTPRemoteConfigFetcher` and the URL-based store initializer against a mocked `URLSession` endpoint.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var requestPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Request")
                    .font(.headline)

                infoRow(title: "URL", value: model.endpoint)
                infoRow(title: "Header", value: "Authorization: Bearer demo-token")
                infoRow(title: "Timeout", value: "8 seconds")

                HStack(spacing: 12) {
                    Button("Load From HTTP") {
                        model.load()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isLoading)

                    Button("Advance Server Revision") {
                        model.advanceRevision()
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
                }

                infoRow(title: "Status", value: model.statusMessage)
                infoRow(title: "Last refresh result", value: model.lastRefreshResult)
                infoRow(title: "Server revision", value: "\(model.serverRevision)")
                infoRow(title: "Fetch count", value: "\(model.fetchCount)")
                infoRow(title: "Last loaded", value: model.lastLoadedAt.map { Self.dateFormatter.string(from: $0) } ?? "Not loaded yet")

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var valuesPanel: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("Decoded Values")
                    .font(.headline)

                Text("These values come through the built-in HTTP fetcher, then read from the store with typed keys.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                if model.rows.isEmpty {
                    Text("Load from HTTP to see the decoded payload.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 0) {
                        ForEach(model.rows) { row in
                            infoRow(title: row.title, value: row.value)

                            if row.id != model.rows.last?.id {
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
}

#Preview {
    NavigationStack {
        HTTPFetcherDemoView()
    }
}
