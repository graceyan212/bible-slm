import SwiftUI
import BibleStoryCore

/// The story player: a single scrolling story surface (art → text → Christ Connection →
/// memory-verse chip → wonder pause), with an in-lesson Ask-Poli sheet and Continue.
struct StoryView: View {
    let env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var showAsk = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.orange.opacity(0.2))
                    .frame(height: 180)
                    .overlay(Text("🎨").font(.system(size: 60)))

                Text("✦ The Rescuer · Story 4").font(.caption).foregroundStyle(.secondary)
                Text("The Brave Shepherd Boy").font(.title).bold()

                Text("Long ago, a young shepherd named David loved God with his whole heart. "
                   + "While the soldiers were afraid of the giant Goliath, David remembered how "
                   + "God had helped him before…")
                Text("So David picked up five smooth stones, and with God's help, he was brave.")

                GroupBox("How it points to Jesus") {
                    Text("Just like God rescued his people through a shepherd, one day he would "
                       + "send the Good Shepherd, Jesus, to rescue us all.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Label("Memory verse (from your family's Bible): 1 Samuel 17 — tap to read together",
                      systemImage: "book")
                    .font(.footnote).foregroundStyle(.secondary)

                Text("✧ I wonder… what does that show you about how big God is?")
                    .italic()
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button { showAsk = true } label: {
                    Label("Ask Poli", systemImage: "questionmark.circle.fill")
                }
                Spacer()
                Button("Continue ✦") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.thinMaterial)
        }
        .sheet(isPresented: $showAsk) {
            AskPoliSheet(env: env)
                .presentationDetents([.medium, .large])
        }
        .navigationTitle("Story")
        .navigationBarTitleDisplayMode(.inline)
    }
}
