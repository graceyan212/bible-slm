import BibleStoryCore

/// Runs `primary`; on ANY failure (device below the RAM floor, model load failure, or a
/// generation error) transparently falls back to `secondary` so Ask-Poli never dead-ends.
/// Updates `ModelLoadState` so the UI can stop showing "waking Poli up…" once we know the
/// outcome (ready on the real model, or silently on the scripted fallback).
struct FallbackModelEngine: ModelEngine {
    let primary: ModelEngine
    let secondary: ModelEngine

    func generate(system: String, messages: [ChatMessage]) async throws -> String {
        do {
            let output = try await primary.generate(system: system, messages: messages)
            await MainActor.run { ModelLoadState.shared.phase = .ready }
            return output
        } catch {
            await MainActor.run { ModelLoadState.shared.phase = .usingFallback }
            return try await secondary.generate(system: system, messages: messages)
        }
    }
}
