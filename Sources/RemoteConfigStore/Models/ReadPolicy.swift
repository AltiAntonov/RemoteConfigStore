import Foundation

public enum ReadPolicy: Sendable, Equatable {
    case immediate
    case waitForRefresh
    case immediateWithBackgroundRefresh
}
