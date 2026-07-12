import SwiftUI
import UserNotifications
import BibleStoryCore

/// First-run onboarding, in the Treasure Trail storybook/treasure-map aesthetic.
///
/// Flow (designed with the `onboarding-architect` skill; see
/// docs/research/12-onboarding-flow-spec.md + 13-onboarding-copy-deck.md):
///
///   1. Welcome ............. Poli + the outcome hook
///   2. Founder's note ...... "we're parents too" — trust before any ask
///   3. Story preview ....... the grown-up walks through a REAL story as their child will (the sale)
///   4. Parent gate ......... hold-to-continue; setup + plan stay in the grown-up's hands
///   5. Name ................ the child's name (used everywhere after)
///   6. Age ................. 7 / 8 / 9
///   7. Family's Bible ...... translation Poli points back to
///   8. Where you are ....... current Bible-time habit (grace-framed)
///   9. Your hope ........... what they want the child to carry
///  10. Your worry .......... surfaced here, answered on the Promise
///  11. Building ........... a short delight beat while the plan is charted
///  12. Plan reveal ........ the personalized journey (reflects the answers)
///  13. Parent Promise ..... the trust keystone (answers the worry)
///  14. Social proof ....... loved by Christian families
///  15. Notification prime .. custom screen before the OS prompt
///  16. Paywall ............ honest free-trial (annual default, "Most Popular", timeline)
///  17. Explorer ........... the child picks an avatar
///  18. Finale ............. celebrate → **Enter the trail map**
///
/// The final CTA calls the SAME completion contract as before —
/// `env.completeOnboarding(child:translation:)` — now with the REAL name + age
/// collected in the quiz. That wiring is the functional invariant.
struct OnboardingView: View {
    let env: AppEnvironment

    enum Step: Int, CaseIterable {
        case welcome, founder, storyIntro, gate,
             name, age, bible, habit, hope, worry,
             building, plan, promise, social, notify,
             paywall, explorer, finale
    }

    /// The quiz steps that show the "filling map path" progress dots.
    private static let quizSteps: [Step] = [.name, .age, .bible, .habit, .hope, .worry]

    @State private var step: Step = .welcome
    @State private var childName = ""
    @State private var age: Int? = nil
    @State private var translation: BibleTranslation = .nirv
    @State private var habit: String? = nil
    @State private var hope: String? = nil
    @State private var worry: String? = nil
    @State private var avatar: String? = nil
    @State private var annualPlan = true
    @State private var showStory = false
    @State private var gateHeld = false

    /// The child's display name once entered; a warm fallback before then.
    private var name: String {
        let trimmed = childName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "your explorer" : trimmed
    }
    private var possessive: String { "\(name)'s" }

    private let explorers: [(emoji: String, label: String, accent: Color)] = [
        ("🦊", "Fox",   OnbColors.custom(0xFF9E5A)),
        ("🦉", "Owl",   OnbColors.custom(0x8B6BFF)),
        ("🐻", "Bear",  OnbColors.custom(0x37E0C8)),
        ("🦁", "Lion",  OnbColors.custom(0xFFD25E)),
        ("🐰", "Bunny", OnbColors.custom(0xFF83C0)),
        ("🐼", "Panda", OnbColors.custom(0xECF1FF)),
    ]

    private let habitOptions = [
        "We're just getting started",
        "We try, but it's on-and-off",
        "We have a rhythm, and want to grow it",
        "It's mostly at church",
    ]
    private let hopeOptions = ["Courage", "Kindness", "Wonder at God", "Knowing they're loved", "Wisdom for hard choices"]
    private let worryOptions = ["Will it get the Bible right?", "Screen time", "Is it safe & private?", "Will it try to replace me?"]

    var body: some View {
        ZStack {
            OnbBackground()
            OnbMapFlecks()

            if step == .finale {
                finale.transition(.opacity)
            } else {
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
            }
        }
        .fullScreenCover(isPresented: $showStory) {
            // The REAL story reader, so the grown-up experiences exactly what their
            // child will. Closing it advances to the parent gate.
            StoryView(env: env, storyID: "creation", onClose: {
                showStory = false
                go(to: .gate)
            })
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.environment["ONB_AUTOCOMPLETE"] == "1" { complete() }
            #endif
        }
    }

    // MARK: Chrome

    private var topBar: some View {
        ZStack {
            if let idx = Self.quizSteps.firstIndex(of: step) {
                OnbDots(count: Self.quizSteps.count, current: idx + 1)
            }
            HStack {
                Button {
                    back()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(OnbColors.ink)
                        .frame(width: 44, height: 44)
                        .background(Circle().stroke(OnbColors.sepiaLine, lineWidth: 3))
                }
                .opacity(step == .welcome ? 0 : 1)
                .disabled(step == .welcome)
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
            case .welcome:
                primary("Begin the journey ✦") { go(to: .founder) }
            case .founder:
                primary("Sounds good ✦") { go(to: .storyIntro) }
            case .storyIntro:
                primary("Play a story ▶") { showStory = true }
                ghost("Maybe later") { go(to: .gate) }
            case .gate:
                EmptyView()   // the hold-to-continue control lives in the body
            case .name:
                primary("Continue ✦") { go(to: .age) }
                    .disabled(childName.trimmingCharacters(in: .whitespaces).isEmpty)
            case .age:
                primary("Continue ✦") { go(to: .bible) }.disabled(age == nil)
            case .bible:
                primary("Continue ✦") { go(to: .habit) }
            case .habit:
                primary("Continue ✦") { go(to: .hope) }.disabled(habit == nil)
            case .hope:
                primary("Continue ✦") { go(to: .worry) }.disabled(hope == nil)
            case .worry:
                primary("Continue ✦") { go(to: .building) }.disabled(worry == nil)
            case .building:
                EmptyView()   // auto-advances
            case .plan:
                primary("This looks right ✦") { go(to: .promise) }
            case .promise:
                primary("I trust this — continue ✦") { go(to: .social) }
            case .social:
                primary("Continue ✦") { go(to: .notify) }
            case .notify:
                primary("Yes, a gentle reminder") { requestNotifications(); go(to: .paywall) }
                ghost("Not now") { go(to: .paywall) }
            case .paywall:
                primary("Start \(possessive) free week") { go(to: .explorer) }
                ghost("Maybe later") { go(to: .explorer) }
            case .explorer:
                primary("That's me! ✦") { go(to: .finale) }.disabled(avatar == nil)
            case .finale:
                EmptyView()
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func primary(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(title, action: action).buttonStyle(OnbPrimaryButtonStyle())
    }
    private func ghost(_ title: String, _ action: @escaping () -> Void) -> some View {
        Button(title, action: action).buttonStyle(OnbGhostButtonStyle())
    }

    // MARK: Steps

    @ViewBuilder
    private var stepBody: some View {
        switch step {
        case .welcome:    welcomeStep
        case .founder:    founderStep
        case .storyIntro: storyIntroStep
        case .gate:       gateStep
        case .name:       nameStep
        case .age:        ageStep
        case .bible:      bibleStep
        case .habit:      selectStep(eyebrowText: "For grown-ups", poli: nil,
                                     title: "Where are you today?",
                                     prompt: "How does Bible time look in your home right now? There's no wrong answer — it just sets where \(name)'s path begins.",
                                     options: habitOptions, selection: $habit)
        case .hope:       selectStep(eyebrowText: "For grown-ups",
                                     poli: "I'll weave this through the stories we choose.",
                                     title: "Your hope for \(name)",
                                     prompt: "What do you most want \(name) to carry with them?",
                                     options: hopeOptions, selection: $hope)
        case .worry:      selectStep(eyebrowText: "For grown-ups", poli: nil,
                                     title: "Be honest with us",
                                     prompt: "What makes you a little cautious about a Bible app? Whatever you pick, we'll speak to it in a moment.",
                                     options: worryOptions, selection: $worry)
        case .building:   buildingStep
        case .plan:       planStep
        case .promise:    promiseStep
        case .social:     socialStep
        case .notify:     notifyStep
        case .paywall:    paywallStep
        case .explorer:   explorerStep
        case .finale:     EmptyView()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 18) {
            eyebrow("True North")
            OnbSpeechBubble(text: "Hi there! I'm Poli, your family's compass. ✦")
                .padding(.bottom, 6)
            OnbPoli(height: 200, pose: .waving)
            glowTitle("A gentle path through the Bible", size: 34)
                .multilineTextAlignment(.center)
            Text("Reverent story-readings for ages 7–9 — built to hand the big questions back to you.")
                .font(OnbFont.body(18))
                .foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 330)
            Text("Reviewed by pastors · No ads · No chat · Nothing collected about your child")
                .font(OnbFont.body(12))
                .foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }

    private var founderStep: some View {
        VStack(spacing: 16) {
            eyebrow("A note from us · just once")
            OnbPoli(height: 92)
            card {
                VStack(alignment: .leading, spacing: 12) {
                    Text("We're parents too — and we built True North for our own kids first.")
                        .font(OnbFont.body(17, .bold)).foregroundStyle(OnbColors.ink)
                    Text("Every story is told faithfully, in Poli's own warm words. Real verses come straight from your family's Bible. True North will never pretend to be your child's pastor or their friend — when they wonder about the hard, holy things, Poli sends them home to you.")
                        .font(OnbFont.body(15)).foregroundStyle(OnbColors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                    Text("— The True North family · aligned with the Baptist Faith & Message (2000)")
                        .font(OnbFont.hand(18)).foregroundStyle(OnbColors.brassDeep)
                }
            }
        }
    }

    private var storyIntroStep: some View {
        VStack(spacing: 16) {
            eyebrow("See it for yourself")
            OnbPoli(height: 120, pose: .pointing)
            glowTitle("Walk through a story", size: 30)
            Text("Take two minutes — press play and experience exactly what your explorer will, from the first page to the wondering-question at the end. This is the app.")
                .font(OnbFont.body(17))
                .foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 330)
            OnbSpeechBubble(text: "I'll read you \u{201C}The Storm That Obeyed.\u{201D} ✦")
                .padding(.top, 4)
        }
    }

    private var gateStep: some View {
        VStack(spacing: 18) {
            OnbPoli(height: 110)
            glowTitle("Grown-ups, this part's for you", size: 26)
                .multilineTextAlignment(.center)
            Text("Just a quick check so the setup and plan stay in your hands.")
                .font(OnbFont.body(16)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            holdToContinue.padding(.top, 6)
            Text("Press and hold the compass to continue.")
                .font(OnbFont.body(13)).foregroundStyle(OnbColors.inkSoft)
        }
    }

    /// A light parent gate: press-and-hold (0.7s) to proceed — keeps setup + the
    /// paywall out of a 7-year-old's reach without blocking a testing grown-up.
    private var holdToContinue: some View {
        ZStack {
            Circle().fill(OnbColors.surface)
                .overlay(Circle().stroke(OnbColors.outline, lineWidth: 3))
            Circle().fill(OnbColors.brass.opacity(gateHeld ? 0.35 : 0))
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(OnbColors.brassDeep)
        }
        .frame(width: 96, height: 96)
        .scaleEffect(gateHeld ? 0.92 : 1)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: gateHeld)
        .gesture(
            LongPressGesture(minimumDuration: 0.7)
                .onChanged { _ in gateHeld = true }
                .onEnded { _ in gateHeld = false; go(to: .name) }
        )
        .accessibilityLabel("Press and hold to continue as a grown-up")
        .accessibilityAddTraits(.isButton)
    }

    private var nameStep: some View {
        VStack(spacing: 16) {
            eyebrow("For grown-ups")
            OnbPoli(height: 84)
            OnbSpeechBubble(text: "Who are we journeying with?")
            TextField("First name or nickname", text: $childName)
                .font(OnbFont.title(24))
                .foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .padding(.vertical, 14)
                .padding(.horizontal, 20)
                .background(RoundedRectangle(cornerRadius: 18).fill(OnbColors.surface))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(OnbColors.sepiaLine, lineWidth: 2))
                .frame(maxWidth: 320)
            Text("We only use it to make the journey feel like theirs — it never leaves this device.")
                .font(OnbFont.body(13)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center).frame(maxWidth: 320)
        }
    }

    private var ageStep: some View {
        VStack(spacing: 16) {
            eyebrow("For grown-ups")
            OnbPoli(height: 84)
            Text("How old is \(name)?")
                .font(OnbFont.title(25)).foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                ForEach([7, 8, 9], id: \.self) { n in
                    OnbChip(text: "\(n)", selected: age == n) { age = n }
                }
            }
            Text("Sets the reading level and which stories come first.")
                .font(OnbFont.body(13)).foregroundStyle(OnbColors.inkSoft)
        }
    }

    private var bibleStep: some View {
        VStack(spacing: 14) {
            eyebrow("For grown-ups")
            OnbPoli(height: 84)
            Text("Any verse I point to comes straight from your Bible.")
                .font(OnbFont.hand(20)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
            Text("Your family's Bible")
                .font(OnbFont.title(25)).foregroundStyle(OnbColors.ink)
            Text("Pick the translation your family reads. Poli always retells stories in its own words — exact verses come from this one.")
                .font(OnbFont.body(16)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center).lineSpacing(3).frame(maxWidth: 340)
            VStack(spacing: 10) {
                ForEach(BibleTranslation.allCases, id: \.self) { t in translationRow(t) }
            }
            .padding(.top, 6)
            .frame(maxWidth: 360)
        }
    }

    /// A reusable single-select question screen (habit / hope / worry).
    private func selectStep(eyebrowText: String, poli: String?, title: String,
                            prompt: String, options: [String],
                            selection: Binding<String?>) -> some View {
        VStack(spacing: 14) {
            eyebrow(eyebrowText)
            OnbPoli(height: 76)
            if let poli { OnbSpeechBubble(text: poli) }
            Text(title).font(OnbFont.title(25)).foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
            Text(prompt).font(OnbFont.body(15)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center).lineSpacing(3).frame(maxWidth: 340)
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { opt in
                    optionRow(opt, selected: selection.wrappedValue == opt) {
                        selection.wrappedValue = opt
                    }
                }
            }
            .padding(.top, 4)
            .frame(maxWidth: 360)
        }
    }

    private func optionRow(_ label: String, selected: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? OnbColors.brassDeep : OnbColors.sepiaLine)
                Text(label).font(OnbFont.body(16, selected ? .bold : .regular))
                    .foregroundStyle(OnbColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 13).padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(selected ? OnbColors.sand : OnbColors.surface))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(selected ? OnbColors.brass : OnbColors.sepiaLine, lineWidth: selected ? 3 : 2))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }

    private var buildingStep: some View {
        VStack(spacing: 18) {
            OnbPoli(height: 120)
            glowTitle("Charting \(possessive) path…", size: 26)
                .multilineTextAlignment(.center)
            Text("Choosing stories for \((hope ?? "wonder").lowercased())… setting a gentle pace…")
                .font(OnbFont.hand(19)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center).frame(maxWidth: 320)
            ProgressView().tint(OnbColors.brassDeep).scaleEffect(1.2).padding(.top, 4)
        }
        .task(id: step) {
            guard step == .building else { return }
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if step == .building { go(to: .plan) }
        }
    }

    private var planStep: some View {
        VStack(spacing: 14) {
            eyebrow("\(name)'s journey")
            glowTitle("12 weeks through the Story", size: 27)
                .multilineTextAlignment(.center)
            card {
                VStack(alignment: .leading, spacing: 12) {
                    planBullet("timer", "About 10 minutes a night, at your pace — no streaks, no pressure.")
                    planBullet("bubble.left.and.bubble.right.fill", "One \u{201C}wondering question\u{201D} to talk over together each night.")
                    planBullet("book.closed.fill", "Verses shown from your \(translation.displayName).")
                    planBullet("sparkles", "Chosen to help \(name) grow in \((hope ?? "wonder").lowercased()).")
                    planBullet("leaf.fill", planStartLine, tint: OnbColors.sage)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(OnbColors.sage)
                Text("First stop: The Storm That Obeyed — you've already seen this one.")
                    .font(OnbFont.body(13)).foregroundStyle(OnbColors.inkSoft)
            }
        }
    }

    private var planStartLine: String {
        switch habit {
        case habitOptions[0]: return "Starting gently, since you're just getting started."
        case habitOptions[3]: return "Bringing church stories home, one night at a time."
        default:              return "Building on the rhythm you already have."
        }
    }

    private func planBullet(_ icon: String, _ text: String, tint: Color = OnbColors.brassDeep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint).frame(width: 24)
            Text(text).font(OnbFont.body(15)).foregroundStyle(OnbColors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var promiseStep: some View {
        VStack(spacing: 16) {
            eyebrow("Our promise to you")
            OnbPoli(height: 88)
            if let worry {
                Text("You told us: \u{201C}\(worry)\u{201D}")
                    .font(OnbFont.hand(19)).foregroundStyle(OnbColors.brassDeep)
                    .multilineTextAlignment(.center)
            }
            card {
                VStack(alignment: .leading, spacing: 16) {
                    OnbPromiseRow(icon: "book.closed.fill", title: "Told faithfully.",
                                  detail: "Poli retells in its own words and never quotes Scripture wrong — real verses come from your \(translation.displayName).")
                    OnbPromiseRow(icon: "checkmark.seal.fill", title: "Sound doctrine.",
                                  detail: "Reviewed by pastors; aligned with the Baptist Faith & Message (2000).")
                    OnbPromiseRow(icon: "figure.wave", title: "Never your child's pastor.",
                                  detail: "Poli gives no spiritual advice — the big questions come home to you.")
                    OnbPromiseRow(icon: "lock.fill", title: "A walled garden.",
                                  detail: "No ads, no chat, no strangers. Ever.")
                    OnbPromiseRow(icon: "hand.raised.fill", title: "Nothing taken.",
                                  detail: "No data collected about your child, and never used to train any AI.")
                    OnbPromiseRow(icon: "house.fill", title: "Yours to leave.",
                                  detail: "Cancel anytime, in two taps.", tint: OnbColors.terracotta)
                }
            }
        }
    }

    private var socialStep: some View {
        VStack(spacing: 16) {
            eyebrow("Loved by Christian families")
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.system(size: 16)).foregroundStyle(OnbColors.brass)
                }
                Text("4.8").font(OnbFont.body(16, .bold)).foregroundStyle(OnbColors.ink)
            }
            testimonial("I was nervous about anything \u{201C}AI\u{201D} near the Bible. But it just retells the stories — faithfully — and when my daughter asked a hard question, it sent her to me. That's what sold me.", "Rachel, mom of two")
            testimonial("We'd been meaning to do this for years. Ten minutes after dinner, and now it just… happens.", "David, dad")
        }
    }

    private func testimonial(_ quote: String, _ who: String) -> some View {
        card {
            VStack(alignment: .leading, spacing: 8) {
                Text("\u{201C}\(quote)\u{201D}")
                    .font(OnbFont.body(15)).foregroundStyle(OnbColors.ink)
                    .fixedSize(horizontal: false, vertical: true).lineSpacing(3)
                Text("— \(who)").font(OnbFont.body(13, .bold)).foregroundStyle(OnbColors.inkSoft)
            }
        }
    }

    private var notifyStep: some View {
        VStack(spacing: 16) {
            OnbPoli(height: 110)
            OnbSpeechBubble(text: "Want a gentle nudge at story time?")
            Text("One quiet evening reminder — the kind that turns a good intention into a habit. No guilt, no streaks. Off anytime.")
                .font(OnbFont.body(16)).foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center).lineSpacing(3).frame(maxWidth: 330)
        }
    }

    private var paywallStep: some View {
        VStack(spacing: 14) {
            eyebrow("For grown-ups")
            glowTitle("Keep walking with \(name)", size: 25)
                .multilineTextAlignment(.center)
            Text("You've seen the first story. The whole journey — reverent, safe, and yours to guide — is ready when you are.")
                .font(OnbFont.body(16)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center).lineSpacing(3).frame(maxWidth: 330)

            VStack(spacing: 12) {
                planCard(annual: true,  title: "Family · Yearly",  price: "$39.99 / year",
                         note: "7-day free trial · about $3.33 a month", badge: "MOST POPULAR")
                planCard(annual: false, title: "Monthly", price: "$5.99 / month",
                         note: "billed monthly", badge: nil)
            }

            card {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How your free week works")
                        .font(OnbFont.body(16, .bold)).foregroundStyle(OnbColors.ink)
                    trialRow(icon: "lock.open.fill", tint: OnbColors.sage,
                             text: "Today — full access unlocks. No charge.")
                    trialRow(icon: "bell.fill", tint: OnbColors.brassDeep,
                             text: "Day 5 — a friendly reminder before your trial ends.")
                    trialRow(icon: "checkmark.circle.fill", tint: OnbColors.caramel,
                             text: "Day 7 — your plan begins, only if you keep it. Cancel anytime in Settings.")
                }
            }

            Text("This is a preview — no charge yet.  Cancel anytime · Restore purchase")
                .font(OnbFont.body(12)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private var explorerStep: some View {
        VStack(spacing: 14) {
            OnbPoli(height: 84, pose: .pointing)
            Text("Now the fun part — who's exploring today?")
                .font(OnbFont.hand(20)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
            Text("Pick your explorer")
                .font(OnbFont.title(26)).foregroundStyle(OnbColors.ink)
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
            OnbPoli(height: 130, pose: .celebrating)
            glowTitle("You're all set, \(name)!", size: 28)
                .multilineTextAlignment(.center)
            Text("Your trail is glowing and ready. Let's go light your very first star together.")
                .font(OnbFont.body(17)).foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center).lineSpacing(4).frame(maxWidth: 320)

            HStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text(avatar ?? "🦊").font(.system(size: 34))
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(OnbColors.surface))
                        .overlay(Circle().stroke(OnbColors.outline, lineWidth: 3))
                    Text("your explorer").font(OnbFont.body(13)).foregroundStyle(OnbColors.inkSoft)
                }
                Text("✦").font(.system(size: 26)).foregroundStyle(OnbColors.brass)
                VStack(spacing: 4) {
                    Image(systemName: "book.fill").font(.system(size: 26))
                        .foregroundStyle(OnbColors.caramel)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(OnbColors.surface))
                        .overlay(Circle().stroke(OnbColors.outline, lineWidth: 3))
                    Text(translation.displayName).font(OnbFont.body(13)).foregroundStyle(OnbColors.inkSoft)
                }
            }
            .padding(.vertical, 16).padding(.horizontal, 24)
            .background(RoundedRectangle(cornerRadius: 24).fill(OnbColors.caramel.opacity(0.14)))
            .overlay(RoundedRectangle(cornerRadius: 24)
                .strokeBorder(OnbColors.brass.opacity(0.55),
                              style: StrokeStyle(lineWidth: 2, dash: [6, 5])))

            Spacer(minLength: 0)

            VStack(spacing: 12) {
                primary("Enter the trail map →") { complete() }
                ghost("Start over") { resetFlow() }
            }
        }
        .padding(.horizontal, 26).padding(.vertical, 20)
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
                Text(price).font(OnbFont.body(16, .bold)).foregroundStyle(OnbColors.ink).fixedSize()
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
        Text(s.uppercased()).font(OnbFont.caps(13)).tracking(3).foregroundStyle(OnbColors.inkSoft)
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

    private func go(to s: Step) {
        withAnimation(.easeInOut(duration: 0.32)) { step = s }
    }

    /// Back one step in declaration order (never past .welcome).
    private func back() {
        guard let prev = Step(rawValue: step.rawValue - 1) else { return }
        go(to: prev)
    }

    private func resetFlow() {
        childName = ""; age = nil; habit = nil; hope = nil; worry = nil; avatar = nil
        go(to: .welcome)
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// The preserved functional invariant: hand the chosen explorer + translation to
    /// the environment, which advances the app phase `.onboarding → .child`. Now uses
    /// the REAL name + age collected in the quiz (falling back gracefully if skipped).
    private func complete() {
        let finalName = childName.trimmingCharacters(in: .whitespaces)
        env.completeOnboarding(
            child: ChildProfile(name: finalName.isEmpty ? "Explorer" : finalName,
                                age: age ?? 8,
                                avatar: avatar ?? "🦊"),
            translation: translation
        )
    }
}
