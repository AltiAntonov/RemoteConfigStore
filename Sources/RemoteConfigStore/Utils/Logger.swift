import Foundation

public protocol Logger: Sendable {
    func log(_ message: @autoclosure () -> String)
}

public struct NoopLogger: Logger {
    public init() {}

    public func log(_ message: @autoclosure () -> String) {}
}
