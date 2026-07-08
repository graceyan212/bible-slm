import Observation

/// Single source of truth for which zone the app is showing.
@MainActor
@Observable
public final class AppModel {
    /// The currently displayed zone. Only this type may change it.
    public private(set) var zone: Zone = .child

    /// True while a parent-gate challenge is in flight (for UI + re-entrancy).
    public private(set) var isAuthenticating: Bool = false

    private let gate: ParentGate

    public init(gate: ParentGate) {
        self.gate = gate
    }

    /// Attempts to move from the child zone into the parent zone.
    /// Requires passing the parent gate — the kid-mode lock.
    /// No-ops if already in the parent zone or a challenge is already running.
    public func enterParentZone() async {
        guard zone == .child, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let didAuthenticate = await gate.authenticate()
        if didAuthenticate {
            zone = .parent
        }
    }

    /// Returns to the child zone. Always allowed — no gate needed to leave.
    public func exitToChildZone() {
        zone = .child
    }
}
