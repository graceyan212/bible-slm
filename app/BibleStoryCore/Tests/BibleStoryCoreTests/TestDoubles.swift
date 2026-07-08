import Foundation
@testable import BibleStoryCore

/// A gate that returns a fixed result immediately, counting calls.
final class MockParentGate: ParentGate, @unchecked Sendable {
    let result: Bool
    private(set) var callCount = 0

    init(result: Bool) {
        self.result = result
    }

    func authenticate() async -> Bool {
        callCount += 1
        return result
    }
}

/// A gate whose `authenticate()` stays suspended until the test calls
/// `complete(with:)`, so we can observe the in-flight state deterministically.
@MainActor
final class ControllableParentGate: ParentGate {
    private(set) var callCount = 0
    private var continuation: CheckedContinuation<Bool, Never>?

    nonisolated init() {}

    func authenticate() async -> Bool {
        callCount += 1
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func complete(with result: Bool) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}
