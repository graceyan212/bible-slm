import SwiftUI

/// App-lifetime, observable state for the on-device model's first load/download, so the
/// Ask-Poli screen can show a friendly "waking Poli up…" message while the ~2 GB model
/// downloads from Hugging Face on first launch (it caches after that). Shared singleton —
/// there is exactly one model for the app.
@MainActor
@Observable
final class ModelLoadState {
    static let shared = ModelLoadState()

    enum Phase: Equatable {
        case idle                 // nothing loaded yet
        case downloading(Double)  // first-run Hub download, 0…1
        case loading              // weights loading into memory
        case ready                // model answered — good to go
        case usingFallback        // scripted engine (unsupported device / load failed)
    }

    var phase: Phase = .idle

    /// A friendly one-liner for the UI, or nil once ready / on the silent fallback.
    var banner: String? {
        switch phase {
        case .idle, .ready, .usingFallback:
            return nil
        case .downloading(let p):
            return "Waking Poli up… downloading (\(Int((p * 100).rounded()))%). Just this once!"
        case .loading:
            return "Waking Poli up…"
        }
    }

    private init() {}
}
