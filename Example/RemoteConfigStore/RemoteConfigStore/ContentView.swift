//
//  ContentView.swift
//  RemoteConfigStore
//
//  Presents the example app scenario list.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import SwiftUI

struct ContentView: View {
    private let scenarios: [Scenario] = [
        .init(
            title: "Feature Flags",
            summary: "See typed keys, cache-first reads, and policy-driven refresh behavior with a flag-style config payload.",
            destination: AnyView(FeatureFlagsDemoView())
        ),
        .init(
            title: "HTTP Fetcher",
            summary: "Use the built-in URLSession fetcher and URL-based store initializer with a mocked HTTP endpoint.",
            destination: AnyView(HTTPFetcherDemoView())
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    VStack(spacing: 14) {
                        ForEach(scenarios) { scenario in
                            NavigationLink {
                                scenario.destination
                            } label: {
                                scenarioCard(scenario)
                            }
                            .buttonStyle(.plain)
                        }
                    }
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
            .navigationTitle("Scenarios")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RemoteConfigStore")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("Explore focused examples that show where the package fits best and how its cache policies affect app behavior.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func scenarioCard(_ scenario: Scenario) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(scenario.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(scenario.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct Scenario: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let destination: AnyView
}

#Preview {
    ContentView()
}
