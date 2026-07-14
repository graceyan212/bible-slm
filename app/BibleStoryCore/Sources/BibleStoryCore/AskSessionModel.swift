import Foundation
import Observation

/// One entry in the ask thread (a child question, or Poli's reply).
public struct AskTurn: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let isChild: Bool
    public let text: String
    public let response: QuestionResponse?   // set on Poli turns (drives the reply surface)
    public let traceID: UUID?                // set on Poli turns — links a 👍/👎 to its trace

    public init(id: UUID = UUID(), isChild: Bool, text: String,
                response: QuestionResponse? = nil, traceID: UUID? = nil) {
        self.id = id
        self.isChild = isChild
        self.text = text
        self.response = response
        self.traceID = traceID
    }
}

/// Drives the ask-a-question interaction: the Poli state machine, the transcript,
/// and the multi-turn history the responder needs to HOLD under pushback.
/// Shared by the full Compass screen and the in-lesson Ask-Poli sheet.
@MainActor
@Observable
public final class AskSessionModel {
    public enum PoliState: Sendable, Equatable { case idle, listening, thinking, answering }

    public private(set) var poliState: PoliState = .idle
    public private(set) var thread: [AskTurn] = []
    /// The latest response (nil until first answer). Consumers key crisis/deflect routing off this.
    public private(set) var response: QuestionResponse?

    /// Grown-up ratings by trace id (drives the 👍/👎 selected state).
    public private(set) var feedbackByTrace: [UUID: TraceFeedback] = [:]

    private var history: [ConversationTurn] = []
    private let responder: QuestionResponder
    private let context: StoryContext
    private let tracer: any Tracer
    private let modelVersion: String

    /// Called with the child's question whenever a reply DEFLECTS to the grown-up,
    /// so the app can log it to the parent's Wonderings. Set by the composition root.
    public var onDeflect: (@MainActor (String) -> Void)?

    /// Called (with NO child text — privacy) when a reply is a danger/crisis, so the app can
    /// open the crisis flow. Set by the composition root.
    public var onCrisis: (@MainActor () -> Void)?

    public init(responder: QuestionResponder,
                context: StoryContext,
                tracer: any Tracer = NoOpTracer(),
                modelVersion: String = "scripted") {
        self.responder = responder
        self.context = context
        self.tracer = tracer
        self.modelVersion = modelVersion
    }

    /// The view calls this when the mic opens (on-device STT happens in the app layer).
    public func beginListening() {
        guard poliState == .idle else { return }
        poliState = .listening
    }

    /// Submit a question (from voice transcription, the text field, or a topic chip).
    public func submit(_ question: String) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, poliState != .thinking else { return }

        thread.append(AskTurn(isChild: true, text: trimmed))
        poliState = .thinking

        let start = Date()
        let reply = await responder.respond(to: trimmed, context: context, history: history)
        let latencyMs = Int(Date().timeIntervalSince(start) * 1000)
        response = reply
        if reply.logToConversationGuide { onDeflect?(trimmed) }   // → parent's Wonderings
        if reply.isCrisis { onCrisis?() }                          // → crisis flow (P7)
        history.append(ConversationTurn(question: trimmed, reply: reply.spokenText))

        // Observability: one trace per interaction (on-device; export is consent-gated).
        let traceID = UUID()
        tracer.record(InteractionTrace(
            id: traceID,
            sessionID: tracer.sessionID,
            createdAt: Date(),
            question: trimmed,
            behaviorClass: reply.behaviorClass.rawValue,
            tier: reply.tier.rawValue,
            crisisFired: reply.isCrisis,
            deflected: reply.logToConversationGuide,
            responseText: reply.spokenText,
            latencyMs: latencyMs,
            modelVersion: modelVersion
        ))

        thread.append(AskTurn(isChild: false, text: reply.spokenText, response: reply, traceID: traceID))
        poliState = .answering
    }

    /// A grown-up rates Poli's answer (👍/👎). Records to the tracer + updates UI state.
    public func rate(_ feedback: TraceFeedback, for traceID: UUID) {
        tracer.setFeedback(feedback, for: traceID)
        feedbackByTrace[traceID] = feedback
    }

    /// Called when the spoken reply finishes / the child dismisses — back to resting.
    public func finishAnswering() {
        poliState = .idle
    }
}
