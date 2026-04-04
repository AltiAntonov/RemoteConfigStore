//
//  ContentView.swift
//  RemoteConfigStore
//
//  Provides a placeholder host screen for the example app.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import RemoteConfigStore
import SwiftUI

struct ContentView: View {
    private let demoKey = RemoteConfigKey<Bool>("demo_feature", defaultValue: false)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RemoteConfigStore")
                .font(.largeTitle.bold())

            Text("Example app scaffold")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Linked package key: \(demoKey.name)")
                .font(.body.monospaced())
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
