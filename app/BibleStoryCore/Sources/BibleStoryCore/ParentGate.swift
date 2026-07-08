/// Presents the parent-authentication challenge (biometric / device passcode).
/// The core package depends only on this protocol so it stays testable;
/// the concrete implementation lives in the app target.
public protocol ParentGate: Sendable {
    /// Returns `true` iff the parent successfully authenticated.
    func authenticate() async -> Bool
}
