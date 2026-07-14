import Foundation

/// A grown-up's rating of one Poli answer — the highest-signal feedback for iterating.
public enum TraceFeedback: String, Sendable, Codable, Equatable {
    case up, down
}

/// One traced interaction: what the child asked, how the pipeline classified + answered it,
/// which guards fired, and how it performed. The unit of observability for the beta.
///
/// **Privacy (COPPA):** `sessionID` is an anonymous per-launch UUID — **never a name**.
/// `question` + `responseText` are the child's/Poli's words; they stay **on-device** and only
/// leave it through the **consent-gated** exporter (see docs/PARENTAL-CONSENT-BETA.md).
public struct InteractionTrace: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public let sessionID: UUID
    public let createdAt: Date
    public let question: String
    public let behaviorClass: String   // hold / acknowledge / deflect / danger / …
    public let tier: String            // closed / open / deflect / none
    public let crisisFired: Bool
    public let deflected: Bool
    public let responseText: String
    public let latencyMs: Int
    public let modelVersion: String
    public var feedback: TraceFeedback?

    public init(
        id: UUID = UUID(),
        sessionID: UUID,
        createdAt: Date,
        question: String,
        behaviorClass: String,
        tier: String,
        crisisFired: Bool,
        deflected: Bool,
        responseText: String,
        latencyMs: Int,
        modelVersion: String,
        feedback: TraceFeedback? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.createdAt = createdAt
        self.question = question
        self.behaviorClass = behaviorClass
        self.tier = tier
        self.crisisFired = crisisFired
        self.deflected = deflected
        self.responseText = responseText
        self.latencyMs = latencyMs
        self.modelVersion = modelVersion
        self.feedback = feedback
    }
}

/// Records interaction traces + feedback. Default `NoOpTracer` ships in production; the beta
/// uses `LocalTraceStore` (on-device). MainActor-isolated so `@Observable` stores conform cleanly.
@MainActor
public protocol Tracer: Sendable {
    /// Anonymous id for the current app session (never a name).
    var sessionID: UUID { get }
    func record(_ trace: InteractionTrace)
    func setFeedback(_ feedback: TraceFeedback, for traceID: UUID)
}

/// No-op tracer — records nothing. The production default (and used in tests).
public struct NoOpTracer: Tracer {
    public let sessionID = UUID()
    public init() {}
    public func record(_ trace: InteractionTrace) {}
    public func setFeedback(_ feedback: TraceFeedback, for traceID: UUID) {}
}
