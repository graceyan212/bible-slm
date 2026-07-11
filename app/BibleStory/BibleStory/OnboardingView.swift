import SwiftUI
import BibleStoryCore

/// First-run onboarding, in the Treasure Trail storybook/treasure-map aesthetic.
///
/// A warm, Poli-guided flow a grown-up sets up *with* their child, then hands over:
///   1. Poli welcome ................ "Hi! I'm Poli, your compass on the adventure!"
///   2. For grown-ups: the promise .. private · guide-not-friend · never misquotes ·
///                                    SBC (BF&M) tradition · grace-not-guilt
///   3. Your family's Bible ......... pick the translation Poli points back to
///   4. Unlock the whole trail ...... honest, calm free-trial (annual default, no FOMO)
///   5. Pick your explorer .......... the child chooses an avatar
///   6. Finale ...................... celebrate → **Enter the trail map**
///
/// The final CTA calls the SAME completion contract the previous onboarding used —
/// `env.completeOnboarding(child:translation:)` — which flips the AppEnvironment
/// phase `.onboarding → .child`, entering the child/map zone. That wiring is the
/// functional invariant; everything else here is presentation.
struct OnboardingView: View {
    let env: AppEnvironment

    private let stepCount = 5   // the dotted setup steps; step 6 is the finale

    @State private var step = OnboardingView.initialStep
    @State private var translation: BibleTranslation = .nirv
    @State private var avatar: String? = OnboardingView.initialAvatar
    @State private var annualPlan = true

    /// Deep-link the initial page for screenshots / SwiftUI previews via the
    /// `ONB_STEP` (1–6) env var. DEBUG-only (compiled out of Release), harmless in
    /// normal launches (unset ⇒ page 1); it only changes which page shows first.
    private static var initialStep: Int {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["ONB_STEP"],
           let n = Int(raw), (1...6).contains(n) { return n }
        #endif
        return 1
    }
    private static var initialAvatar: String? {
        // pre-select an explorer when deep-linking the explorer/finale pages
        (initialStep >= 5) ? "🦊" : nil
    }

    private let explorers: [(emoji: String, label: String, accent: Color)] = [
        ("🦊", "Fox",   OnbColors.custom(0xFF9E5A)),
        ("🦉", "Owl",   OnbColors.custom(0x8B6BFF)),
        ("🐻", "Bear",  OnbColors.custom(0x37E0C8)),
        ("🦁", "Lion",  OnbColors.custom(0xFFD25E)),
        ("🐰", "Bunny", OnbColors.custom(0xFF83C0)),
        ("🐼", "Panda", OnbColors.custom(0xECF1FF)),
    ]

    var body: some View {
        ZStack {
            OnbBackground()
            OnbMapFlecks()

            if step <= stepCount {
                VStack(spacing: 0) {
                    topBar
                    GeometryReader { geo in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                stepBody
                                Spacer(minLength: 0)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: geo.size.height)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 8)
                        }
                    }
                    footer
                }
                .transition(.opacity)
                .id(step)
            } else {
                finale
                    .transition(.opacity)
            }
        }
        .task {
            #if DEBUG
            // Verification hook: exercise the completion wiring end-to-end so the
            // resulting child/map zone can be screenshotted. DEBUG-only; unset ⇒ no-op.
            if ProcessInfo.processInfo.environment["ONB_AUTOCOMPLETE"] == "1" { complete() }
            #endif
        }
    }

    // MARK: Chrome

    private var topBar: some View {
        ZStack {
            OnbDots(count: stepCount, current: step)
            HStack {
                Button {
                    go(to: max(1, step - 1))
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(OnbColors.ink)
                        .frame(width: 44, height: 44)
                        .background(Circle().stroke(OnbColors.sepiaLine, lineWidth: 3))
                }
                .opacity(step > 1 ? 1 : 0)
                .disabled(step <= 1)
                .accessibilityLabel("Go back a step")
                Spacer()
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 12) {
            switch step {
            case 1:
                Button("Start the adventure ✦") { go(to: 2) }.buttonStyle(OnbPrimaryButtonStyle())
            case 2:
                Button("Sounds good — let's set up ✦") { go(to: 3) }.buttonStyle(OnbPrimaryButtonStyle())
            case 3:
                Button("Continue ✦") { go(to: 4) }.buttonStyle(OnbPrimaryButtonStyle())
            case 4:
                Button("Start my free trial") { go(to: 5) }.buttonStyle(OnbPrimaryButtonStyle())
                Button("Maybe later") { go(to: 5) }.buttonStyle(OnbGhostButtonStyle())
            default:
                Button("That's me! ✦") { go(to: 6) }
                    .buttonStyle(OnbPrimaryButtonStyle())
                    .disabled(avatar == nil)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    // MARK: Steps

    @ViewBuilder
    private var stepBody: some View {
        switch step {
        case 1: welcomeStep
        case 2: promiseStep
        case 3: bibleStep
        case 4: paywallStep
        default: explorerStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 18) {
            eyebrow("Treasure Trail")
            OnbSpeechBubble(text: "Hi there, explorer! I'm so glad you found me. ✦")
                .padding(.bottom, 6)
            OnbPoli(height: 208, pose: .waving)
            glowTitle("Hi! I'm Poli!", size: 40)
            Text("I'm your compass on the adventure! Together we'll follow the map and uncover the greatest stories ever told — one stop at a time.")
                .font(OnbFont.body(18))
                .foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 320)
        }
    }

    private var promiseStep: some View {
        VStack(spacing: 16) {
            eyebrow("For grown-ups · just once")
            OnbPoli(height: 96)
            Text("Before Poli meets your explorer")
                .font(OnbFont.title(25))
                .foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
            card {
                VStack(alignment: .leading, spacing: 16) {
                    OnbPromiseRow(icon: "lock.fill", title: "Private by design.",
                                  detail: "Runs on this device and stays parent-gated — no open chat with the internet.")
                    OnbPromiseRow(icon: "figure.wave", title: "A guide, never a friend.",
                                  detail: "Poli helps with Bible stories; it never pretends to be a person or a confidant.")
                    OnbPromiseRow(icon: "book.closed.fill", title: "Never misquotes Scripture.",
                                  detail: "Poli retells in its own warm words — real verses come from your family's Bible.")
                    OnbPromiseRow(icon: "checkmark.seal.fill", title: "Your tradition.",
                                  detail: "Taught from the Southern Baptist Convention (Baptist Faith & Message).")
                    OnbPromiseRow(icon: "house.fill", title: "Grace, not guilt.",
                                  detail: "Big or tender questions come home to you, with a gentle way to talk them through.",
                                  tint: OnbColors.terracotta)
                }
            }
            Text("Set it up together, then hand the device to your little explorer.")
                .font(OnbFont.body(14))
                .foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }

    private var bibleStep: some View {
        VStack(spacing: 14) {
            eyebrow("For grown-ups")
            OnbPoli(height: 84)
            Text("Any verse I point to comes straight from your Bible.")
                .font(OnbFont.hand(20))
                .foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
            Text("Your family's Bible")
                .font(OnbFont.title(25))
                .foregroundStyle(OnbColors.ink)
            Text("Pick the translation your family reads. Poli always retells stories in its own words — exact verses come from this one.")
                .font(OnbFont.body(16))
                .foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 340)
            VStack(spacing: 10) {
                ForEach(BibleTranslation.allCases, id: \.self) { t in translationRow(t) }
            }
            .padding(.top, 6)
            .frame(maxWidth: 360)
        }
    }

    private var paywallStep: some View {
        VStack(spacing: 14) {
            eyebrow("For grown-ups")
            OnbPoli(height: 74)
            Text("Unlock the whole trail")
                .font(OnbFont.title(25))
                .foregroundStyle(OnbColors.ink)
            Text("Every story, every stop — and Poli always ready to help your explorer wonder.")
                .font(OnbFont.body(16))
                .foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 330)

            VStack(spacing: 12) {
                planCard(annual: true,  title: "Yearly",  price: "$39.99 / year",
                         note: "7-day free trial · about $3.33 a month", badge: "BEST VALUE")
                planCard(annual: false, title: "Monthly", price: "$5.99 / month",
                         note: "billed monthly", badge: nil)
            }

            card {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How your free trial works")
                        .font(OnbFont.body(16, .bold)).foregroundStyle(OnbColors.ink)
                    trialRow(icon: "lock.open.fill", tint: OnbColors.sage,
                             text: "Today — free. Explore the first stops and meet Poli, no charge.")
                    trialRow(icon: "bell.fill", tint: OnbColors.brassDeep,
                             text: "Day 5 — a friendly reminder before your trial ends.")
                    trialRow(icon: "checkmark.circle.fill", tint: OnbColors.caramel,
                             text: "Day 7 — your plan begins, only if you keep it. Cancel anytime in Settings.")
                }
            }

            Text("This is a preview — no charge yet.  Cancel anytime · Restore purchase")
                .font(OnbFont.body(12))
                .foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private var explorerStep: some View {
        VStack(spacing: 14) {
            OnbPoli(height: 84, pose: .pointing)
            Text("Now the fun part — who's exploring today?")
                .font(OnbFont.hand(20))
                .foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
            Text("Pick your explorer")
                .font(OnbFont.title(26))
                .foregroundStyle(OnbColors.ink)
            let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(explorers, id: \.emoji) { e in
                    OnbChoiceTile(emoji: e.emoji, label: e.label, accent: e.accent,
                                  selected: avatar == e.emoji) {
                        avatar = e.emoji
                    }
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: Finale

    private var finale: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            OnbPoli(height: 132, pose: .celebrating)
            glowTitle("You're all set, explorer!", size: 30)
                .multilineTextAlignment(.center)
            Text("Your trail is glowing and ready. Let's go light your very first star together.")
                .font(OnbFont.body(17))
                .foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 320)

            HStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text(avatar ?? "🦊")
                        .font(.system(size: 34))
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(OnbColors.surface))
                        .overlay(Circle().stroke(OnbColors.outline, lineWidth: 3))
                    Text("your explorer").font(OnbFont.body(13)).foregroundStyle(OnbColors.inkSoft)
                }
                Text("✦").font(.system(size: 26)).foregroundStyle(OnbColors.brass)
                VStack(spacing: 4) {
                    Image(systemName: "book.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(OnbColors.caramel)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(OnbColors.surface))
                        .overlay(Circle().stroke(OnbColors.outline, lineWidth: 3))
                    Text(translation.displayName).font(OnbFont.body(13)).foregroundStyle(OnbColors.inkSoft)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 24).fill(OnbColors.caramel.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(OnbColors.brass.opacity(0.55),
                                  style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            )

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                Button("Enter the trail map →") { complete() }
                    .buttonStyle(OnbPrimaryButtonStyle())
                Button("Start over") {
                    avatar = nil
                    go(to: 1)
                }
                .buttonStyle(OnbGhostButtonStyle())
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 20)
    }

    // MARK: Building blocks

    /// A full-width list row for one translation: abbreviation + plain-English name
    /// (so "NIrV" is self-explanatory) with a brass check when selected.
    private func translationRow(_ t: BibleTranslation) -> some View {
        let selected = translation == t
        return Button { translation = t } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(t.displayName)
                        .font(OnbFont.body(18, .bold))
                        .foregroundStyle(OnbColors.ink)
                    Text(translationSubtitle(t))
                        .font(OnbFont.body(13))
                        .foregroundStyle(OnbColors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(OnbColors.ctaInk)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(OnbColors.brass))
                        .overlay(Circle().stroke(OnbColors.outline, lineWidth: 2))
                        .transition(.scale)
                } else {
                    Circle().stroke(OnbColors.sepiaLine, lineWidth: 2).frame(width: 26, height: 26)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 16).fill(selected ? OnbColors.sand : OnbColors.surface))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(selected ? OnbColors.brass : OnbColors.outline, lineWidth: selected ? 3 : 2))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
        .accessibilityLabel("\(t.displayName), \(translationSubtitle(t))")
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }

    private func translationSubtitle(_ t: BibleTranslation) -> String {
        switch t {
        case .nirv: "New International Reader’s Version · easiest for kids"
        case .icb:  "International Children’s Bible · simple for young readers"
        case .esv:  "English Standard Version"
        case .niv:  "New International Version"
        case .kjv:  "King James Version"
        }
    }

    private func planCard(annual: Bool, title: String, price: String, note: String, badge: String?) -> some View {
        let selected = annualPlan == annual
        return Button {
            annualPlan = annual
        } label: {
            HStack(spacing: 14) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? OnbColors.brassDeep : OnbColors.sepiaLine)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(title).font(OnbFont.body(17, .bold)).foregroundStyle(OnbColors.ink)
                        if let badge {
                            Text(badge)
                                .font(OnbFont.body(10, .bold))
                                .foregroundStyle(OnbColors.ctaInk)
                                .padding(.vertical, 3).padding(.horizontal, 8)
                                .background(Capsule().fill(OnbColors.brass))
                                .overlay(Capsule().stroke(OnbColors.outline, lineWidth: 1.5))
                        }
                    }
                    Text(note).font(OnbFont.body(13)).foregroundStyle(OnbColors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text(price).font(OnbFont.body(16, .bold)).foregroundStyle(OnbColors.ink)
                    .fixedSize()
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 20).fill(selected ? OnbColors.sand : OnbColors.surface))
            .overlay(RoundedRectangle(cornerRadius: 20)
                .stroke(selected ? OnbColors.brass : OnbColors.sepiaLine, lineWidth: selected ? 3 : 2))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
        .accessibilityLabel("\(title) plan, \(price)")
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }

    private func trialRow(icon: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint).frame(width: 24)
            Text(text).font(OnbFont.body(14)).foregroundStyle(OnbColors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func eyebrow(_ s: String) -> some View {
        Text(s.uppercased())
            .font(OnbFont.caps(13))
            .tracking(3)
            .foregroundStyle(OnbColors.inkSoft)
    }

    private func glowTitle(_ s: String, size: CGFloat) -> some View {
        Text(s)
            .font(OnbFont.display(size))
            .foregroundStyle(OnbColors.brassDeep)
            .shadow(color: OnbColors.cream, radius: 0, x: 0, y: 1)
            .shadow(color: OnbColors.ink.opacity(0.28), radius: 4, x: 0, y: 2)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24).fill(OnbColors.surface))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(OnbColors.ink.opacity(0.22), lineWidth: 3))
            .shadow(color: OnbColors.ink.opacity(0.18), radius: 12, x: 0, y: 8)
    }

    // MARK: Navigation & the preserved completion contract

    private func go(to n: Int) {
        withAnimation(.easeInOut(duration: 0.32)) { step = n }
    }

    /// The functional invariant preserved from the original onboarding: hand the
    /// chosen explorer + translation to the environment, which advances the app
    /// phase `.onboarding → .child` (RootView then shows HomeView, the trail map).
    private func complete() {
        env.completeOnboarding(
            child: ChildProfile(name: "Explorer", age: 8, avatar: avatar ?? "🦊"),
            translation: translation
        )
    }
}
