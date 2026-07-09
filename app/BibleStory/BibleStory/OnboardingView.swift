import SwiftUI
import BibleStoryCore

/// First-run: grown-up gate → parent setup (translation; sign-in/trial stubbed) →
/// kid onboarding (pick your explorer) → enter the trail.
struct OnboardingView: View {
    let env: AppEnvironment

    private enum Step { case gate, parentSetup, kid }
    @State private var step: Step = .gate
    @State private var translation: BibleTranslation = .nirv
    @State private var avatar = "🦊"

    var body: some View {
        switch step {
        case .gate: grownupGate
        case .parentSetup: parentSetup
        case .kid: kidOnboarding
        }
    }

    private var grownupGate: some View {
        VStack(spacing: 16) {
            Text("👋 Grown-up first").font(.title).bold()
            VStack(alignment: .leading, spacing: 8) {
                Label("Private — runs on this device", systemImage: "lock.fill")
                Label("A guide, never a friend", systemImage: "figure.wave")
                Label("Never misquotes Scripture", systemImage: "book.closed")
                Label("Southern Baptist (BF&M) tradition", systemImage: "checkmark.seal")
                Label("Hard questions go home to you", systemImage: "house")
            }
            .font(.callout)
            Button("I'm a grown-up — let's begin ✦") { step = .parentSetup }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var parentSetup: some View {
        VStack(spacing: 20) {
            Text("Your family's Bible").font(.title2).bold()
            Text("Any verse Poli points to will match this translation.")
                .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Picker("Translation", selection: $translation) {
                ForEach(BibleTranslation.allCases, id: \.self) { t in
                    Text(t.displayName).tag(t)
                }
            }
            .pickerStyle(.segmented)
            Text("(Sign in with Apple + free trial — wired in P2)")
                .font(.caption2).foregroundStyle(.secondary)
            Button("Continue ✦") { step = .kid }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var kidOnboarding: some View {
        VStack(spacing: 24) {
            Text("Pick your explorer!").font(.title).bold()
            HStack(spacing: 16) {
                ForEach(["🦊", "🦉", "🐻", "🦁"], id: \.self) { emoji in
                    Button(emoji) { avatar = emoji }
                        .font(.system(size: 44))
                        .padding(8)
                        .background(avatar == emoji ? Color.yellow.opacity(0.3) : .clear, in: Circle())
                }
            }
            Button("Enter the trail map →") {
                env.completeOnboarding(
                    child: ChildProfile(name: "Explorer", age: 8, avatar: avatar),
                    translation: translation
                )
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
