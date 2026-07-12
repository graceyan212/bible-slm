#if os(iOS)
import Foundation
import Observation
import AVFoundation

/// Poli's spoken voice — reads replies aloud (the `.answering` half of the ask loop).
/// Text-to-speech needs no permission (unlike the mic), so this always works.
/// Kid-tuned: a touch slower and slightly higher-pitched than the system default.
@MainActor
@Observable
public final class PoliVoice: NSObject, AVSpeechSynthesizerDelegate {
    public private(set) var isSpeaking = false
    /// Parent/quiet-mode switch. When false, `speak` is a no-op (still fires onFinish).
    public var enabled = true

    private let synth = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    public override init() {
        super.init()
        synth.delegate = self
    }

    /// Speak `text` aloud, then call `onFinish` (also called immediately if muted/empty).
    public func speak(_ text: String, onFinish: (() -> Void)? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard enabled, !trimmed.isEmpty else { onFinish?(); return }
        self.onFinish = onFinish

        // Route to the speaker (audible even with the silent switch on) and duck others.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? session.setActive(true)

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.rate = 0.46               // default ~0.5 — a little slower for young ears
        utterance.pitchMultiplier = 1.15     // slightly higher = warmer/younger
        utterance.postUtteranceDelay = 0.1
        if let voice = AVSpeechSynthesisVoice(language: "en-US") { utterance.voice = voice }

        isSpeaking = true
        synth.speak(utterance)
    }

    /// Stop any current speech (e.g. the child taps the mic to talk again).
    public func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
        isSpeaking = false
    }

    // MARK: AVSpeechSynthesizerDelegate (callbacks arrive off the main actor)

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                              didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finish() }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer,
                                              didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.finish() }
    }

    private func finish() {
        isSpeaking = false
        // Release the session so a following mic capture can take `.record` cleanly.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        let callback = onFinish
        onFinish = nil
        callback?()
    }
}
#endif
