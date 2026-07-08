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
