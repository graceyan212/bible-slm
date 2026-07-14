import Foundation
import Observation

/// On-device store of sanitized `CrisisEvent`s for the parent dashboard. Newest first.
/// Nothing leaves the device (privacy/COPPA). Mirrors `WonderingsStore`.
@MainActor
@Observable
public final class CrisisEventStore {
    public private(set) var events: [CrisisEvent] = []

    private let key = "tn.crisisEvents.v1"
    private let store = UserDefaults.standard

    public init() {
        if let data = store.data(forKey: key),
           let saved = try? JSONDecoder().decode([CrisisEvent].self, from: data) {
            events = saved
        }
    }

    public func record(_ event: CrisisEvent) {
        events.insert(event, at: 0)
        persist()
    }

    /// Parent can clear reviewed concerns.
    public func clear() {
        events = []
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(events) {
            store.set(data, forKey: key)
        }
    }
}
