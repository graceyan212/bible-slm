import Foundation

/// One chat message handed to a `ModelEngine`.
public struct ChatMessage: Sendable, Equatable {
    public enum Role: String, Sendable, Equatable { case system, user, assistant }
    public let role: Role
    public let content: String
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}

/// Raw text-generation seam. Plain text in, plain text out.
///
/// The tuned SBC model emits warm prose only — `behavior_class` / `tier` / `claim_ids`
/// are training metadata, NOT model output — so generation and routing/classification
/// are separate concerns (`GuidedResponder` handles the latter around this engine).
///
/// Phase C ships `ScriptedModelEngine`; Phase A ships the on-device `MLXModelEngine`.
public protocol ModelEngine: Sendable {
    /// Generate the assistant reply for `messages`, with `system` as the system prompt.
    /// `messages` contains only user/assistant turns (system is passed separately).
    func generate(system: String, messages: [ChatMessage]) async throws -> String
}
