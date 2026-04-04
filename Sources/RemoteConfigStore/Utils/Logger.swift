//
//  Logger.swift
//  RemoteConfigStore
//
//  Provides lightweight logging hooks for store activity.
//  Copyright (c) 2026 Altimir Antonov.
//  Licensed under the MIT License. See LICENSE for details.
//

import Foundation

public protocol Logger: Sendable {
    func log(_ message: @autoclosure () -> String)
}

public struct NoopLogger: Logger {
    public init() {}

    public func log(_ message: @autoclosure () -> String) {}
}
