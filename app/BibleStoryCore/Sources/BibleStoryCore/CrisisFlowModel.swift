import Foundation
import Observation

/// Drives the danger/crisis pathway (P7). On `trigger(...)` it records a **sanitized** event,
/// alerts a caregiver (no transcript), and flips `isPresenting` so the app shows the calm
/// crisis screen. Fire-toward-safety: the caller invokes this whenever a response is `.danger`
/// / `isCrisis`.
///
/// ⚠️ The child-facing copy, the resources, and the escalation routing here are **SAFE
/// PLACEHOLDERS**. A licensed child-safety / clinical professional must review and sign the
/// wording AND the self-harm-vs-abuse escalation before this ships (docs/SAFETY-AND-COPPA.md
/// §2 + §5). In particular, abuse disclosures must NOT assume the parent is a safe adult.
@MainActor
@Observable
public final class CrisisFlowModel {
    public var isPresenting = false
    public let resources: [CrisisResource]

    private let alertService: CrisisAlertService
    private let store: CrisisEventStore

    public init(
        alertService: CrisisAlertService = NoOpCrisisAlertService(),
        store: CrisisEventStore,
        resources: [CrisisResource] = CrisisResources.usPlaceholder
    ) {
        self.alertService = alertService
        self.store = store
        self.resources = resources
    }

    /// Present the calm screen, persist a sanitized event, and alert the caregiver.
    /// `reason` is a FIXED category label supplied by the caller (never the child's words);
    /// it is sanitized defensively regardless.
    public func trigger(childID: UUID, reason: String, at now: Date = Date()) async {
        let event = CrisisEvent(
            id: UUID(),
            childID: childID,
            createdAt: now,
            triggerSummary: CrisisEvent.sanitizedSummary(from: reason)
        )
        store.record(event)
        isPresenting = true
        await alertService.alertCaregiver(event)
    }

    public func dismiss() { isPresenting = false }

    // MARK: - SAFE PLACEHOLDER child-facing copy (clinician signs the final text)
    // Never counsels · never promises secrecy · never probes · urges a trusted grown-up.
    public static let childHeadline = "That's really important."
    public static let childBody =
        "A grown-up who cares about you should know about this. Please show this to a parent, " +
        "teacher, school counselor, or another grown-up you trust — they will want to help you."
    public static let showGrownUpLabel = "Show a grown-up"
}
