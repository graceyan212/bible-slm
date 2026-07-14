import Foundation

/// Alerts a caregiver that a crisis event occurred — carrying **no transcript**, only a
/// neutral prompt to open the parent area (privacy: docs/SAFETY-AND-COPPA.md §2.6). The
/// concrete implementation (local notification / APNs) lives in the app target; core stays
/// testable via `NoOpCrisisAlertService`.
public protocol CrisisAlertService: Sendable {
    func alertCaregiver(_ event: CrisisEvent) async
}

/// Default no-op (used in tests and until a concrete alert service is injected).
public struct NoOpCrisisAlertService: CrisisAlertService {
    public init() {}
    public func alertCaregiver(_ event: CrisisEvent) async {}
}
