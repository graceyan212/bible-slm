// STAGED — not in the build until mlx-swift dep + converted model are added (Phase A).
//
// This file is a PREP artifact. It is NOT compiled by the app target yet: `project.yml`
// has no `mlx-swift-examples` SPM dependency, and there is no converted on-device model
// bundled or downloaded. Do not move this into `BibleStory/BibleStory/` until both land.
//
// Target API surface: `mlx-swift-examples` (https://github.com/ml-explore/mlx-swift-examples),
// packages `MLXLLM` + `MLXLMCommon`. Written against the shape of that API as of the
// 2026 releases documented in the repo's `Libraries/MLXLLM` + `Libraries/MLXLMCommon` READMEs.
//
// ⚠️ API calls to VERIFY when the dependency is actually added (mlx-swift-examples' public
// surface has moved before across versions — confirm signatures against the pinned tag):
//   - `LLMModelFactory.shared.loadContainer(hub:configuration:progressHandler:)` — exact
//     overload/argument order, and whether `hub: HubApi` is required or defaults.
//   - `ModelConfiguration(directory:)` — confirm this initializer exists for loading a
//     *local* directory (vs. only `id:` for Hub repos). Some versions require
//     `ModelConfiguration(directory:defaultPrompt:)` or a custom `ModelRegistry` entry.
//   - `ModelContainer.perform { context in ... }` vs. direct `context.model` access — confirm
//     the actor-isolation shape used to run generation against the loaded container.
//   - `MLXLMCommon.generate(input:parameters:context:didGenerate:)` free function vs.
//     `ChatSession(container:).respond(to:)` convenience wrapper — this file uses the
//     lower-level `generate` path; `ChatSession` may be simpler once available and should
//     be reconsidered.
//   - `UserInput(chat:)` / `UserInput.Chat.Message(role:content:)` — confirm this is how
//     chat-templated prompts are built for Qwen3, and that the Qwen3 tokenizer's chat
//     template (`apply_chat_template`) is applied automatically inside `UserInput` → the
//     model's `Processor`/tokenizer, not something this file must hand-roll.
//   - `GenerateParameters(maxTokens:temperature:)` — confirm field names/defaults (some
//     versions use `maxTokens` vs `maxTokenCount`, `temperature` vs `temp`).
//   - Whether Qwen3 requires a specific `ModelType`/registry entry in `LLMModelFactory` or
//     works generically as a `LanguageModel` via config.json `model_type` sniffing.

import Foundation
// import MLX
// import MLXLLM
// import MLXLMCommon
// import BibleStoryCore   // for ModelEngine, ChatMessage

/// Errors surfaced by `MLXModelEngine`.
public enum MLXModelEngineError: Error, Sendable {
    /// The model directory doesn't exist yet (not downloaded) or failed integrity checks.
    case modelUnavailable
    /// Loading the model container into memory failed.
    case loadFailed(underlying: String)
    /// Generation failed or produced no text.
    case generationFailed(underlying: String)
    /// Device is below the RAM floor to safely load a 4-bit 4B model.
    case deviceUnsupported
}

/// On-device inference engine: runs the fine-tuned Qwen3-4B-Instruct-2507 (+ QLoRA adapter,
/// merged, 4-bit quantized, converted via `mlx_lm convert`) via `mlx-swift-examples`.
///
/// Conforms to `ModelEngine` (see `BibleStoryCore/Sources/BibleStoryCore/ModelEngine.swift`):
///     func generate(system: String, messages: [ChatMessage]) async throws -> String
///
/// Loading is lazy and async: the first `generate(...)` call triggers the load and caches the
/// resulting `ModelContainer` for the lifetime of this instance. Callers (e.g. `GuidedResponder`
/// per the on-device-responder design) should fall back to `ScriptedModelEngine` if this throws
/// `.modelUnavailable` or `.deviceUnsupported`.
public final class MLXModelEngine: /* ModelEngine, */ @unchecked Sendable {

    /// Directory containing the converted MLX model (weights + config + tokenizer),
    /// e.g. the unpacked output of `ModelDownloadManager`.
    private let modelDirectory: URL

    /// Generation caps — deliberately conservative for a 7-9-year-old's Q&A turn and for
    /// on-device latency/battery.
    private let maxTokens: Int
    private let temperature: Float

    /// Cached container, loaded once. Guarded by `loadTask` so concurrent `generate` calls
    /// await the same in-flight load rather than double-loading.
    // private var cachedContainer: ModelContainer?
    private var loadTask: Task<Void, Error>?
    private var cachedContainerBox: AnyObject? // placeholder for `ModelContainer` until dep is added

    private let minimumSupportedRAMBytes: UInt64 = 6 * 1_000_000_000 // ~6GB floor; product targets 8GB+ devices

    public init(
        modelDirectory: URL,
        maxTokens: Int = 350,
        temperature: Float = 0.7
    ) {
        self.modelDirectory = modelDirectory
        self.maxTokens = maxTokens
        self.temperature = temperature
    }

    // MARK: - ModelEngine

    public func generate(system: String, messages: [ChatMessagePlaceholder]) async throws -> String {
        try checkDeviceSupported()
        // let container = try await loadedContainer()
        //
        // let chat: [UserInput.Chat.Message] =
        //     [.system(system)] +
        //     messages.map { message in
        //         switch message.role {
        //         case .user: return .user(message.content)
        //         case .assistant: return .assistant(message.content)
        //         case .system: return .system(message.content) // shouldn't occur; system is passed separately
        //         }
        //     }
        //
        // let input = UserInput(chat: chat)
        //
        // let parameters = GenerateParameters(maxTokens: maxTokens, temperature: temperature)
        //
        // let result: String = try await container.perform { context in
        //     let lmInput = try await context.processor.prepare(input: input)
        //     var text = ""
        //     let _ = try MLXLMCommon.generate(
        //         input: lmInput,
        //         parameters: parameters,
        //         context: context
        //     ) { tokens in
        //         // stream callback; accumulate final text via context.tokenizer.decode(tokens:)
        //         return .more
        //     }
        //     text = context.tokenizer.decode(tokens: /* final token ids */ [])
        //     return text
        // }
        //
        // let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        // guard !trimmed.isEmpty else {
        //     throw MLXModelEngineError.generationFailed(underlying: "empty generation")
        // }
        // return trimmed

        throw MLXModelEngineError.modelUnavailable // scaffolding: real body above is staged, not live
    }

    // MARK: - Loading (lazy, cached, async)

    // Uncomment and adapt once MLXLLM/MLXLMCommon are linked:
    //
    // private func loadedContainer() async throws -> ModelContainer {
    //     if let cached = cachedContainer { return cached }
    //     if let existingLoad = loadTask {
    //         try await existingLoad.value
    //         guard let cached = cachedContainer else {
    //             throw MLXModelEngineError.loadFailed(underlying: "load task completed without a container")
    //         }
    //         return cached
    //     }
    //
    //     let task = Task<Void, Error> { [weak self] in
    //         guard let self else { return }
    //         guard FileManager.default.fileExists(atPath: self.modelDirectory.path) else {
    //             throw MLXModelEngineError.modelUnavailable
    //         }
    //         do {
    //             let configuration = ModelConfiguration(directory: self.modelDirectory)
    //             let container = try await LLMModelFactory.shared.loadContainer(
    //                 configuration: configuration
    //             ) { progress in
    //                 // optional: surface load progress to a UI state
    //             }
    //             self.cachedContainer = container
    //         } catch {
    //             throw MLXModelEngineError.loadFailed(underlying: String(describing: error))
    //         }
    //     }
    //     loadTask = task
    //     try await task.value
    //     guard let cached = cachedContainer else {
    //         throw MLXModelEngineError.loadFailed(underlying: "load task completed without a container")
    //     }
    //     return cached
    // }

    // MARK: - Device guard

    private func checkDeviceSupported() throws {
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        guard physicalMemory >= minimumSupportedRAMBytes else {
            throw MLXModelEngineError.deviceUnsupported
        }
    }
}

/// Placeholder mirroring `BibleStoryCore.ChatMessage` so this file type-checks standalone
/// while staged outside the app target. Delete this and import `BibleStoryCore`'s real
/// `ChatMessage` (and conform to the real `ModelEngine` protocol) when wiring in Phase A.
public struct ChatMessagePlaceholder: Sendable, Equatable {
    public enum Role: String, Sendable, Equatable { case system, user, assistant }
    public let role: Role
    public let content: String
    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
}
