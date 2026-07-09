import SwiftUI
import BibleStoryCore

/// Placeholder for the parent dashboard (built out in Plan P6: Conversation Guide /
/// Wonderings journal, content & safety controls, progress).
struct ParentZoneView: View {
    let env: AppEnvironment

    var body: some View {
        VStack(spacing: 24) {
            Text("Parent Dashboard").font(.largeTitle)
            Text("Conversation Guide · Controls · Progress\n(coming in P6)")
                .font(.footnote).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Return to Stories") { env.exitToChildZone() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
