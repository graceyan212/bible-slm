import SwiftUI
import BibleStoryCore

/// Full-screen Ask-Poli (reached from the Home Poli dock / Ask tab): talk OR type
/// to the mascot + a guided-topic picker. Uses the environment's shared responder
/// seam and real on-device speech-to-text (SpeechDictation).
struct CompassView: View {
    let env: AppEnvironment
    var onClose: (() -> Void)? = nil
    @State private var session: AskSessionModel?

    var body: some View {
        Group {
            if let session {
                VoiceAskView(session: session, showTopics: true)
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Ask Poli")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(onClose != nil)
        .toolbar {
            if let onClose {
                ToolbarItem(placement: .topBarLeading) {
                    Button { onClose() } label: {
                        Label("Map", systemImage: "chevron.left")
                    }
                }
            }
        }
        .task {
            if session == nil {
                session = env.makeAskSession(context: Self.context)
            }
        }
    }

    static let context = StoryContext(
        storyID: UUID(),
        storyTitle: "The Brave Shepherd Boy",
        pageIndex: 0,
        pageNarration: "David trusted God and faced the giant Goliath."
    )
}

/// In-lesson Ask-Poli, presented as a bottom sheet so the child stays in the story.
struct AskPoliSheet: View {
    let env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var session: AskSessionModel?

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    VoiceAskView(session: session, showTopics: true)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Ask Poli")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Back to the story") { dismiss() }
                }
            }
            .task {
                if session == nil {
                    session = env.makeAskSession(context: CompassView.context)
                }
            }
        }
    }
}

/// The ask surface: Poli + thread + a "hold to talk OR type" input bar.
/// Voice is real on-device dictation; if the mic isn't available (permission /
/// setup), the child can always type.
struct VoiceAskView: View {
    let session: AskSessionModel
    var showTopics: Bool = false

    @State private var text = ""
    @State private var dictation = SpeechDictation()
    @State private var voice = PoliVoice()

    private let topics = [
        "Noah's Ark", "Why do we get baptized?", "The end of the world",
        "Is my hamster in heaven?", "How did David feel?"
    ]

    var body: some View {
        VStack(spacing: 12) {
            PoliMascotView(state: session.poliState)
                .padding(.top, 8)
                .overlay(alignment: .topTrailing) {
                    Button {
                        voice.enabled.toggle()
                        if !voice.enabled { voice.stop() }
                    } label: {
                        Image(systemName: voice.enabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Theme.brassDeep)
                            .padding(10)
                    }
                    .accessibilityLabel(voice.enabled ? "Mute Poli's voice" : "Unmute Poli's voice")
                }

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if showTopics && session.thread.isEmpty {
                        Text("Not sure? Pick a star ✦")
                            .font(Theme.body(21, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        ForEach(topics, id: \.self) { topic in
                            Button(topic) { Task { await session.submit(topic) } }
                                .font(Theme.body(18))
                                .buttonStyle(.bordered)
                                .tint(Theme.caramel)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    ForEach(session.thread) { turn in
                        if turn.isChild {
                            Text(turn.text)
                                .font(Theme.body(18))
                                .foregroundStyle(Theme.ink)
                                .padding(12)
                                .background(Theme.sea.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else if let response = turn.response {
                            ReplySurfaceView(response: response)
                        }
                    }
                }
                .padding(.horizontal)
            }

            inputBar
        }
        .background(Theme.parchment.ignoresSafeArea())
        // Mirror the live (partial) transcript into the field while recording.
        .onChange(of: dictation.transcript) { _, newValue in
            if dictation.isRecording { text = newValue }
        }
        // Recording just ended (user stopped, or recognizer hit "final"): send it.
        .onChange(of: dictation.isRecording) { wasRecording, nowRecording in
            if wasRecording && !nowRecording {
                let q = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !q.isEmpty { submit(q) }
            }
        }
        // Poli just answered → read it aloud, then settle back to resting.
        .onChange(of: session.poliState) { _, state in
            guard state == .answering else { return }
            let reply = session.thread.last(where: { !$0.isChild })?.text ?? ""
            voice.speak(reply) { session.finishAnswering() }
        }
        .onDisappear { voice.stop() }
    }

    // MARK: Input bar (mic + text + send)

    private var inputBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Button(action: micTapped) {
                    Image(systemName: dictation.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(dictation.isRecording ? Theme.terracotta : Theme.brass)
                        .symbolEffect(.pulse, isActive: dictation.isRecording)
                }
                .accessibilityLabel(dictation.isRecording ? "Stop talking" : "Talk to Poli")

                TextField(dictation.isRecording ? "Listening…" : "Ask Poli…", text: $text)
                    .font(Theme.body(18))
                    .textFieldStyle(.roundedBorder)
                    .disabled(dictation.isRecording)
                    .onSubmit(sendTyped)

                Button("Send", action: sendTyped)
                    .font(Theme.body(18, weight: .bold))
                    .tint(Theme.brass)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty || dictation.isRecording)
            }

            if let hint = voiceHint {
                Text(hint)
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    /// A gentle nudge only when voice can't run — typing always works.
    private var voiceHint: String? {
        switch dictation.availability {
        case .denied:                 return "🎙️ Turn on the mic in Settings to talk — you can still type!"
        case .missingUsageDescription: return "🎙️ Voice needs a quick setup — you can still type!"
        case .unavailable:            return "🎙️ Talking isn't available here — you can still type!"
        case .unknown, .ready:        return nil
        }
    }

    // MARK: Actions

    private func micTapped() {
        if dictation.isRecording {
            _ = dictation.stop()          // flips isRecording → onChange submits
        } else {
            voice.stop()                  // don't let Poli talk over the child
            text = ""
            session.beginListening()
            Task { await dictation.start() }
        }
    }

    private func sendTyped() {
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        text = ""
        submit(q)
    }

    private func submit(_ q: String) {
        text = ""
        Task { await session.submit(q) }
    }
}
