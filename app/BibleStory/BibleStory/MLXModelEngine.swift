import Foundation
import BibleStoryCore

// Compiled only when the mlx-swift-lm libraries are linked (Xcode build with the SPM
// package resolved). Without them — e.g. `swift build` of Core, or CI without the dep —
// the app falls back to `ScriptedModelEngine` (see BibleStoryApp.makeEngine), so the whole
// project still builds. Once the dependency resolves, this real engine takes over.
//
// NOTE: MLXLLM / MLXLMCommon / MLXHuggingFace live in ml-explore/mlx-swift-lm (they were
// moved OUT of mlx-swift-examples). The loader uses the MLXHuggingFace macros
// `#hubDownloader()` + `#huggingFaceTokenizerLoader()` to fetch + cache from the HF Hub.
#if canImport(MLXLLM) && canImport(MLXLMCommon) && canImport(MLXHuggingFace)
import MLXLLM
import MLXLMCommon
import MLXHuggingFace
import HuggingFace   // HubClient / HuggingFace — needed by the #hubDownloader() macro expansion
import Tokenizers    // needed by the #huggingFaceTokenizerLoader() macro expansion

public enum MLXModelEngineError: Error, Sendable {
    case deviceUnsupported
    case loadFailed(underlying: String)
    case generationFailed(underlying: String)
}

/// On-device inference engine: runs the fine-tuned **Qwen3-4B-Instruct-2507** (QLoRA adapter
/// merged, 4-bit MLX), downloaded from the Hugging Face Hub on first use and cached, via
/// `mlx-swift-lm` (`MLXLLM` + `MLXLMCommon` + `MLXHuggingFace`). Conforms to
/// `BibleStoryCore.ModelEngine`.
///
/// An `actor` so the cached container + in-flight load are race-free under Swift 6 concurrency.
/// Loading is lazy: the first `generate(...)` triggers the download/load and caches the
/// `ModelContainer`. Callers fall back to `ScriptedModelEngine` on any thrown error
/// (`FallbackModelEngine` does this).
public actor MLXModelEngine: ModelEngine {

    private let repoID: String
    private let maxTokens: Int
    private let temperature: Float
    private let progressHandler: (@Sendable (Double) -> Void)?

    /// Product targets 8 GB+ devices (iPhone 15 Pro or newer) for a 4-bit 4B model.
    private let minimumRAMBytes: UInt64 = 8 * 1_000_000_000

    private var container: ModelContainer?
    private var loadTask: Task<ModelContainer, Error>?

    public init(
        repoID: String,
        maxTokens: Int = 350,
        temperature: Float = 0.7,
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) {
        self.repoID = repoID
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.progressHandler = progressHandler
    }

    // MARK: - ModelEngine

    public func generate(system: String, messages: [ChatMessage]) async throws -> String {
        try checkDeviceSupported()
        let container = try await loadedContainer()

        // The pipeline hands us history + the new question as the last user turn.
        guard let question = messages.last, question.role == .user else {
            throw MLXModelEngineError.generationFailed(underlying: "no user message to answer")
        }
        // Prior turns become the session's restored history; the system prompt is passed
        // as `instructions` (do NOT also put it in history, or it doubles).
        let history: [Chat.Message] = messages.dropLast().map { message in
            switch message.role {
            case .user:      return .user(message.content)
            case .assistant: return .assistant(message.content)
            case .system:    return .system(message.content)
            }
        }

        let session = ChatSession(
            container,
            instructions: system,
            history: history,
            generateParameters: GenerateParameters(maxTokens: maxTokens, temperature: temperature)
        )

        do {
            let output = try await session.respond(to: question.content)
            let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw MLXModelEngineError.generationFailed(underlying: "empty generation")
            }
            return trimmed
        } catch let error as MLXModelEngineError {
            throw error
        } catch {
            throw MLXModelEngineError.generationFailed(underlying: String(describing: error))
        }
    }

    // MARK: - Loading (lazy, cached, single in-flight)

    private func loadedContainer() async throws -> ModelContainer {
        if let container { return container }
        if let loadTask { return try await loadTask.value }

        let id = repoID
        let handler = progressHandler
        let task = Task<ModelContainer, Error> {
            do {
                let configuration = ModelConfiguration(id: id)
                return try await LLMModelFactory.shared.loadContainer(
                    from: #hubDownloader(),
                    using: #huggingFaceTokenizerLoader(),
                    configuration: configuration
                ) { progress in
                    handler?(progress.fractionCompleted)
                }
            } catch {
                throw MLXModelEngineError.loadFailed(underlying: String(describing: error))
            }
        }
        loadTask = task
        do {
            let loaded = try await task.value
            container = loaded
            loadTask = nil
            return loaded
        } catch {
            loadTask = nil
            throw error
        }
    }

    // MARK: - Device guard

    private func checkDeviceSupported() throws {
        guard ProcessInfo.processInfo.physicalMemory >= minimumRAMBytes else {
            throw MLXModelEngineError.deviceUnsupported
        }
    }
}
#endif
