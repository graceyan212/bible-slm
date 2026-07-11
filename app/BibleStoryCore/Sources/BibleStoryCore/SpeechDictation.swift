#if os(iOS)
import Foundation
import Observation
import Speech
import AVFoundation

/// On-device speech-to-text for "talk to Poli". Lives in the app-layer seam the
/// AskSessionModel expects (`beginListening()` → dictate → `submit(transcript)`).
///
/// Privacy-first for a kids' app: prefers on-device recognition when the device
/// supports it, and NEVER requests authorization unless the app actually declares
/// the required usage strings (doing so without them is a hard crash) — so the UI
/// can always fall back to typing.
@MainActor
@Observable
public final class SpeechDictation {
    public enum Availability: Sendable, Equatable {
        case unknown
        case ready
        case denied                 // user (or Settings) said no
        case unavailable            // no recognizer / device can't
        case missingUsageDescription // Info.plist lacks the privacy strings
    }

    /// Live (partial) transcript while recording; final text after `stop()`.
    public private(set) var transcript: String = ""
    public private(set) var isRecording = false
    public private(set) var availability: Availability = .unknown

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    public init() {}

    /// Requesting mic/speech permission without the Info.plist usage strings is a
    /// guaranteed crash, so gate on their presence first.
    private var hasUsageStrings: Bool {
        let info = Bundle.main.infoDictionary ?? [:]
        return info["NSMicrophoneUsageDescription"] != nil
            && info["NSSpeechRecognitionUsageDescription"] != nil
    }

    /// Ask for speech + mic permission. Safe to call repeatedly. Updates
    /// `availability` and returns true only when recording can begin.
    @discardableResult
    public func requestAuthorization() async -> Bool {
        guard hasUsageStrings else { availability = .missingUsageDescription; return false }
        guard recognizer != nil else { availability = .unavailable; return false }

        let speechStatus = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard speechStatus == .authorized else {
            availability = (speechStatus == .denied || speechStatus == .restricted) ? .denied : .unavailable
            return false
        }

        let micGranted = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
        }
        guard micGranted else { availability = .denied; return false }

        availability = .ready
        return true
    }

    /// Begin live dictation. No-op if already recording or permission is unavailable.
    public func start() async {
        guard !isRecording else { return }
        transcript = ""
        guard await requestAuthorization() else { return }
        do {
            try startEngine()
            isRecording = true
        } catch {
            availability = .unavailable
            _ = stop()
        }
    }

    private func startEngine() throws {
        task?.cancel()
        task = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if recognizer?.supportsOnDeviceRecognition == true {
            req.requiresOnDeviceRecognition = true
        }
        request = req

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        // The tap runs off the main actor; it only appends buffers to the request.
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            req.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer?.recognitionTask(with: req) { [weak self] result, error in
            // Copy out only Sendable values, then hop to the main actor.
            let text = result?.bestTranscription.formattedString
            let done = error != nil || (result?.isFinal ?? false)
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let text { self.transcript = text }
                if done { _ = self.stop() }
            }
        }
    }

    /// Stop recording and return the final transcript.
    @discardableResult
    public func stop() -> String {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        request = nil
        task = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        return transcript
    }
}
#endif
