import Foundation
import LocalAuthentication
import BibleStoryCore

/// Concrete parent gate backed by Face ID / Touch ID, with automatic
/// device-passcode fallback. Returns false on any failure or cancellation.
final class BiometricParentGate: ParentGate {
    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Enter Passcode"

        let policy: LAPolicy = .deviceOwnerAuthentication
        var policyError: NSError?
        guard context.canEvaluatePolicy(policy, error: &policyError) else {
            return false
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(
                policy,
                localizedReason: "Confirm you're a grown-up to open the parent area."
            ) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
