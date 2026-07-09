import SwiftUI
import BibleStoryCore

/// Poli, the trail-compass mascot. One component, state-driven (idle/listening/thinking/answering).
/// Visuals are placeholder — the real "Treasure Trail" skin comes from design/tokens.css later.
struct PoliMascotView: View {
    let state: AskSessionModel.PoliState

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(glow.opacity(0.3)).frame(width: 76, height: 76)
                Text("🧭").font(.system(size: 42))
            }
            Text(caption).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityLabel("Poli, \(caption)")
    }

    private var glow: Color {
        switch state {
        case .idle: .orange
        case .listening: .teal
        case .thinking: .purple
        case .answering: .yellow
        }
    }
    private var caption: String {
        switch state {
        case .idle: "tap to talk"
        case .listening: "listening…"
        case .thinking: "thinking…"
        case .answering: "Poli says…"
        }
    }
}

/// The persistent "ask your guide" button (Home dock). Tapping opens the Compass.
struct PoliFAB: View {
    var state: AskSessionModel.PoliState = .idle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("✦ tap Poli if you have a question")
                    .font(.caption2).foregroundStyle(.secondary)
                PoliMascotView(state: state)
            }
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
    }
}

/// A stop on the treasure-map trail. State = color + icon + size (colorblind-safe).
struct TrailNodeView: View {
    enum NodeState { case locked, active, done, milestone }
    let state: NodeState
    let label: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 12) {
                Text(icon).font(.title2)
                Text(label).font(.headline)
                if state == .active {
                    Spacer()
                    Text("START").font(.caption).bold()
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.yellow, in: Capsule())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(state != .active)
        .accessibilityHint(state == .active ? "Start this story" : "")
    }

    private var icon: String {
        switch state {
        case .locked: "🔒"
        case .active: "✦"
        case .done: "✓"
        case .milestone: "💎"
        }
    }
    private var bg: Color {
        switch state {
        case .locked: .gray.opacity(0.12)
        case .active: .orange.opacity(0.28)
        case .done: .green.opacity(0.15)
        case .milestone: .brown.opacity(0.18)
        }
    }
}

/// Polymorphic reply surface — the tier decides which card renders (behavior-spec v2).
struct ReplySurfaceView: View {
    let response: QuestionResponse

    var body: some View {
        switch response.behaviorClass {
        case .deflect:
            card(icon: "house.fill", tint: .brown) {
                Text(response.spokenText)
            }
        case .danger:
            card(icon: "heart.fill", tint: .red) {
                Text(response.spokenText)
            }
        default:
            card(icon: "sparkles", tint: .orange) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("✦ Poli says").font(.caption).bold()
                    Text(response.spokenText)
                    if response.retrievedVerse != nil || !response.claimIDs.isEmpty {
                        Label("Read it in your Bible with a grown-up", systemImage: "book")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func card(icon: String, tint: Color, @ViewBuilder _ content: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}
