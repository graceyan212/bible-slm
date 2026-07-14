import Foundation
import Observation

/// On-device trace store for the beta (Tracer + reviewable log). Traces persist locally and
/// **never leave the device** here — export is a separate, consent-gated step
/// (`exportJSON()` → the LangFuse exporter). Newest first; capped so it can't grow unbounded.
@MainActor
@Observable
public final class LocalTraceStore: Tracer {
    public private(set) var traces: [InteractionTrace] = []
    /// Anonymous id for this app launch — the only "who", and it's not a name.
    public let sessionID = UUID()

    private let key = "tn.traces.v1"
    private let store = UserDefaults.standard
    private let maxStored = 500

    public init() {
        if let data = store.data(forKey: key),
           let saved = try? JSONDecoder().decode([InteractionTrace].self, from: data) {
            traces = saved
        }
    }

    public func record(_ trace: InteractionTrace) {
        traces.insert(trace, at: 0)
        if traces.count > maxStored {
            traces.removeLast(traces.count - maxStored)
        }
        persist()
    }

    public func setFeedback(_ feedback: TraceFeedback, for traceID: UUID) {
        guard let i = traces.firstIndex(where: { $0.id == traceID }) else { return }
        traces[i].feedback = feedback
        persist()
    }

    /// Everything logged, as JSON — for manual review or the consent-gated exporter.
    public func exportJSON() -> Data? {
        try? JSONEncoder().encode(traces)
    }

    /// Traces a grown-up flagged as wrong — the fastest path to the next dataset iteration.
    public var thumbsDown: [InteractionTrace] {
        traces.filter { $0.feedback == .down }
    }

    public func clear() {
        traces = []
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(traces) {
            store.set(data, forKey: key)
        }
    }
}
