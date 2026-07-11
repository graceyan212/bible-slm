import SwiftUI
import BibleStoryCore

/// Full-screen Ask-Poli (reached from the Home Poli dock): tap-to-talk + text +
/// the guided-topic picker. Uses the environment's shared responder seam.
struct CompassView: View {
    let env: AppEnvironment
    var onClose: (() -> Void)? = nil
    @State private var session: AskSessionModel?

    var body: some View {
        Group {
            if let session {
                AskView(session: session, showTopics: true)
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
                    AskView(session: session, showTopics: true)
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
