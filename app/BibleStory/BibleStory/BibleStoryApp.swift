import SwiftUI
import BibleStoryCore

@main
struct BibleStoryApp: App {
    @State private var env: AppEnvironment

    init() {
        AppFonts.register()   // register bundled IM Fell English / Atkinson faces
        #if DEBUG
        // `-uiPreviewParent` opens the biometric-gated parent dashboard directly
        // (dev/screenshot only): swap in a gate that always passes so the phase can
        // reach `.parent` on a simulator with no enrolled biometrics.
        let gate: ParentGate = ProcessInfo.processInfo.arguments.contains("-uiPreviewParent")
            ? AlwaysPassGate() : BiometricParentGate()
        #else
        let gate: ParentGate = BiometricParentGate()
        #endif
        _env = State(wrappedValue: AppEnvironment(
            // The tiered-stance pipeline (guards + classifier) runs on whatever engine
            // `makeEngine()` returns: the real on-device MLX model when the dependency is
            // linked, else the scripted engine. The pipeline itself is unchanged.
            responder: GuidedResponder(engine: Self.makeEngine()),
            gate: gate,
            crisisAlertService: LocalNotificationCrisisAlertService()
        ))
    }

    /// The on-device model, with a graceful fallback to the scripted engine.
    /// Uses the real MLX engine when `mlx-swift-examples` is linked (Xcode build with the
    /// SPM package resolved); otherwise — and at runtime on a device below the RAM floor or
    /// if the model fails to load — it degrades to `ScriptedModelEngine` so Ask-Poli always works.
    private static func makeEngine() -> ModelEngine {
        #if canImport(MLXLLM) && canImport(MLXLMCommon) && canImport(MLXHuggingFace)
        let mlx = MLXModelEngine(
            repoID: "graceyan212/true-north-sbc-kids-4b-mlx",
            progressHandler: { fraction in
                Task { @MainActor in
                    ModelLoadState.shared.phase = fraction < 1.0 ? .downloading(fraction) : .loading
                }
            }
        )
        return FallbackModelEngine(primary: mlx, secondary: ScriptedModelEngine())
        #else
        return ScriptedModelEngine()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            // Dev/screenshot shortcut: `-uiPreviewReader` shows the Story Reader
            // directly (deterministic; avoids racing the onboarding transition).
            if ProcessInfo.processInfo.arguments.contains("-uiPreviewReader") {
                NavigationStack { StoryView(env: env) }
            } else if ProcessInfo.processInfo.arguments.contains("-uiPreviewAsk") {
                NavigationStack { CompassView(env: env) }
            } else {
                RootView(env: env)
                    .onAppear {
                        let args = ProcessInfo.processInfo.arguments
                        // `-uiPreviewChild` jumps past onboarding straight to the
                        // child-zone treasure map (dev/screenshot only).
                        if args.contains("-uiPreviewChild") {
                            env.completeOnboarding(
                                child: ChildProfile(name: "Explorer", age: 8),
                                translation: .nirv
                            )
                        }
                        #if DEBUG
                        // `-uiPreviewParent` drives on to the gated parent dashboard
                        // (paired with AlwaysPassGate above). Dev/screenshot only.
                        if args.contains("-uiPreviewParent") {
                            env.completeOnboarding(
                                child: ChildProfile(name: "Ruthie", age: 8, avatar: "🦊"),
                                translation: .nirv
                            )
                            Task { await env.enterParentZone() }
                        }
                        #endif
                    }
            }
        }
    }
}

#if DEBUG
/// Dev-only gate that always authenticates, so `-uiPreviewParent` can reach the
/// parent dashboard on a simulator without enrolled biometrics. Never used in release.
private struct AlwaysPassGate: ParentGate {
    func authenticate() async -> Bool { true }
}
#endif
