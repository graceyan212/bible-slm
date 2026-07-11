import SwiftUI
import BibleStoryCore

/// The shared ask-a-question surface: Poli mascot + thread + input.
/// Used full-screen by CompassView and compactly by the in-lesson AskPoliSheet.
struct AskView: View {
    let session: AskSessionModel
    var showTopics: Bool = false

    @State private var text = ""

    private let topics = [
        "Noah's Ark", "Why do we get baptized?", "The end of the world",
        "Is my hamster in heaven?", "How did David feel?"
    ]

    var body: some View {
        VStack(spacing: 12) {
            PoliMascotView(state: session.poliState)
                .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if showTopics && session.thread.isEmpty {
                        Text("Not sure? Pick a star ✦")
                            .font(Theme.body(21, weight: .bold))
                        ForEach(topics, id: \.self) { topic in
                            Button(topic) { Task { await session.submit(topic) } }
                                .font(Theme.body(18))
                                .buttonStyle(.bordered)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    ForEach(session.thread) { turn in
                        if turn.isChild {
                            Text(turn.text)
                                .font(Theme.body(18))
                                .padding(12)
                                .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        } else if let response = turn.response {
                            ReplySurfaceView(response: response)
                        }
                    }
                }
                .padding(.horizontal)
            }

            HStack(spacing: 10) {
                Button { micTapped() } label: {
                    Image(systemName: "mic.circle.fill").font(.system(size: 40))
                }
                .accessibilityLabel("Talk to Poli")

                TextField("Ask Poli…", text: $text)
                    .font(Theme.body(18))
                    .textFieldStyle(.roundedBorder)

                Button("Send") { send() }
                    .font(Theme.body(18, weight: .bold))
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func send() {
        let q = text
        text = ""
        Task { await session.submit(q) }
    }

    /// Stand-in for on-device speech-to-text (wired in P4 app-glue). Shows the
    /// full listen → think → answer cycle with a representative question.
    private func micTapped() {
        session.beginListening()
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            await session.submit("Why do we get baptized?")
        }
    }
}
