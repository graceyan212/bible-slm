import Observation

/// Single source of truth for which zone the app is showing.
@MainActor
@Observable
public final class AppModel {
    /// The currently displayed zone. Only this type may change it.
    public private(set) var zone: Zone = .child

    private let gate: ParentGate

    public init(gate: ParentGate) {
        self.gate = gate
    }

    /// Attempts to move from the child zone into the parent zone.
    /// Requires passing the parent gate — the kid-mode lock.
    public func enterParentZone() async {
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
