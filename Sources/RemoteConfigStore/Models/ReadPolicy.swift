//
//  ReadPolicy.swift
//  RemoteConfigStore
//
//  Describes how cached reads interact with refresh behavior.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

public enum ReadPolicy: Sendable, Equatable {
    case immediate
    case waitForRefresh
    case immediateWithBackgroundRefresh
}
