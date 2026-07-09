import SwiftUI
import BibleStoryCore

enum HomeRoute: Hashable { case story, compass }

/// The child-zone home: the treasure-map trail + HUD + the persistent Poli dock.
/// (Placeholder visuals; the trail/nodes/skin come from the Treasure Trail design later.)
struct HomeView: View {
    let env: AppEnvironment
    @State private var path: [HomeRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Unit 2 · The Rescuer").font(.subheadline).bold()
                        HStack { Text("🔥 5"); Text("✦ 320") }.font(.caption)

                        // Trail reads bottom→top; here top-to-bottom for a simple scroll.
                        TrailNodeView(state: .milestone, label: "Uncover the Lamb")
                        TrailNodeView(state: .locked, label: "The Big Storm")
                        TrailNodeView(state: .active, label: "The Brave Shepherd Boy") {
                            path.append(.story)
                        }
                        TrailNodeView(state: .done, label: "A Boy Named David")
                        Text("🏕️ You started your trail here")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .padding()
                    .padding(.bottom, 120)   // room for the Poli dock
                }

                PoliFAB { path.append(.compass) }
            }
            .navigationTitle("Treasure Trail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await env.enterParentZone() }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    .accessibilityLabel("Parent area")
                    .disabled(env.isAuthenticating)
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .story: StoryView(env: env)
                case .compass: CompassView(env: env)
                }
            }
        }
    }
}
