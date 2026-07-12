import SwiftUI
import UserNotifications
import BibleStoryCore

/// First-run onboarding, in the True North storybook/treasure-map aesthetic.
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
///  17. Finale ............. celebrate → **Enter the trail map**
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
             paywall, finale
    }

    /// The quiz steps that show the "filling map path" progress dots.
    private static let quizSteps: [Step] = [.name, .age, .bible, .habit, .hope, .worry]

    @State private var step: Step = .welcome
    @State private var childName = ""
    @State private var age: Int? = nil
    @State private var translation: BibleTranslation = .nirv
    @State private var habit: String? = nil
    @State private var hopes: Set<String> = []
    @State private var worry: String? = nil        // the concern they last opened (pins on the Promise)
    @State private var expandedWorry: String? = nil
    @State private var annualPlan = true
    @State private var showStory = false
    @State private var gateHeld = false

    /// The child's display name once entered; a warm fallback before then.
    private var name: String {
        let trimmed = childName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "your explorer" : trimmed
    }
    private var possessive: String { "\(name)'s" }

    /// The chosen hopes as a natural phrase ("courage", "courage and kindness",
    /// "courage, kindness, and wonder at God"). Falls back to "wonder" if none.
    private var hopesPhrase: String {
        let items = hopeOptions.filter { hopes.contains($0) }.map { $0.lowercased() }
        switch items.count {
        case 0: return "wonder"
        case 1: return items[0]
        case 2: return "\(items[0]) and \(items[1])"
        default: return items.dropLast().joined(separator: ", ") + ", and " + items.last!
        }
    }

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
                primary("Continue ✦") { go(to: .worry) }.disabled(hopes.isEmpty)
            case .worry:
                primary("Continue ✦") { go(to: .building) }   // informational — no selection required
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
                primary("Start \(possessive) free week") { go(to: .finale) }
                ghost("Maybe later") { go(to: .finale) }
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
        case .habit:      selectStep(title: "How's Bible time at home now?",
                                     subtitle: "So we start \(name)'s path in the right place.",
                                     options: habitOptions, selection: $habit)
        case .hope:       multiSelectStep(title: "What do you hope \(name) grows in?",
                                          subtitle: "Pick as many as you like — we'll lean the stories toward these.",
                                          options: hopeOptions, selection: $hopes)
        case .worry:      worryStep
        case .building:   buildingStep
        case .plan:       planStep
        case .promise:    promiseStep
        case .social:     socialStep
        case .notify:     notifyStep
        case .paywall:    paywallStep
        case .finale:     EmptyView()
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            OnbPoli(height: 210, pose: .waving)
            glowTitle("A gentle path\nthrough the Bible", size: 40)
                .multilineTextAlignment(.center)
            Text("Reverent stories for ages 7–9.")
                .font(OnbFont.body(21))
                .foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
            Text("Reviewed by pastors · No ads · No chat")
                .font(OnbFont.body(15))
                .foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
        }
    }

    private var founderStep: some View {
        VStack(spacing: 16) {
            eyebrow("A note from us · just once")
            OnbPoli(height: 92)
            card {
                VStack(alignment: .leading, spacing: 14) {
                    Text("We're parents too. We built this for our own kids first.")
                        .font(OnbFont.body(20, .bold)).foregroundStyle(OnbColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("When your child wonders about the hard things, Poli sends them to you — never replaces you.")
                        .font(OnbFont.body(17)).foregroundStyle(OnbColors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                    Text("— The True North family")
                        .font(OnbFont.hand(19)).foregroundStyle(OnbColors.brassDeep)
                }
            }
        }
    }

    private var storyIntroStep: some View {
        VStack(spacing: 20) {
            OnbPoli(height: 130, pose: .pointing)
            glowTitle("See a story first", size: 34)
            Text("Experience exactly what your child will.")
                .font(OnbFont.body(21))
                .foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            OnbSpeechBubble(text: "I'll read you \u{201C}The Storm That Obeyed.\u{201D} ✦")
        }
    }

    private var gateStep: some View {
        VStack(spacing: 20) {
            OnbPoli(height: 120)
            glowTitle("Grown-ups only", size: 32)
                .multilineTextAlignment(.center)
            holdToContinue.padding(.top, 6)
            Text("Press and hold to continue.")
                .font(OnbFont.body(16)).foregroundStyle(OnbColors.inkSoft)
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
        VStack(spacing: 20) {
            OnbPoli(height: 96)
            OnbSpeechBubble(text: "Who are we journeying with?")
            TextField("First name", text: $childName)
                .font(OnbFont.title(28))
                .foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(RoundedRectangle(cornerRadius: 18).fill(OnbColors.surface))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(OnbColors.sepiaLine, lineWidth: 2))
                .frame(maxWidth: 320)
        }
    }

    private var ageStep: some View {
        VStack(spacing: 18) {
            OnbPoli(height: 84)
            Text("How old is \(name)?")
                .font(OnbFont.title(30)).foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                ageRow([4, 5, 6])
                // The suggested band — a dotted, labeled box around ages 7–9. Any age
                // is still selectable; the box just signals what we designed for.
                VStack(spacing: 8) {
                    Text("Designed for ages 7–9")
                        .font(OnbFont.caps(12)).tracking(2)
                        .foregroundStyle(OnbColors.brassDeep)
                    ageRow([7, 8, 9])
                }
                .padding(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(OnbColors.brass, style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                )
                ageRow([10, 11, 12])
            }
            .frame(maxWidth: 300)
        }
    }

    private func ageRow(_ ns: [Int]) -> some View {
        HStack(spacing: 12) { ForEach(ns, id: \.self) { ageChip($0) } }
    }

    /// A uniform age chip — no "recommended" tint (the dotted box marks the suggested
    /// band instead). Selected fills brass; any age is selectable.
    private func ageChip(_ n: Int) -> some View {
        let selected = age == n
        return Button { age = n } label: {
            Text("\(n)")
                .font(OnbFont.body(20, .bold))
                .foregroundStyle(selected ? OnbColors.ctaInk : OnbColors.ink)
                .frame(width: 62, height: 54)
                .background(RoundedRectangle(cornerRadius: 16).fill(selected ? OnbColors.brass : OnbColors.surface))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(selected ? OnbColors.outline : OnbColors.sepiaLine, lineWidth: selected ? 3 : 2))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
        .accessibilityLabel("Age \(n)")
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }

    private var bibleStep: some View {
        VStack(spacing: 16) {
            OnbPoli(height: 84)
            Text("Your family's Bible")
                .font(OnbFont.title(30)).foregroundStyle(OnbColors.ink)
            Text("Verses come from the one you pick.")
                .font(OnbFont.body(17)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                ForEach(BibleTranslation.allCases, id: \.self) { t in translationRow(t) }
            }
            .padding(.top, 4)
            .frame(maxWidth: 360)
        }
    }

    /// A short "why we're asking" line under a question title.
    private func questionHead(_ title: String, _ subtitle: String) -> some View {
        VStack(spacing: 8) {
            Text(title).font(OnbFont.title(29)).foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 340)
            Text(subtitle).font(OnbFont.body(16)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 320)
        }
    }

    /// A single-select question screen (habit / worry): pick exactly one.
    private func selectStep(title: String, subtitle: String, options: [String],
                            selection: Binding<String?>) -> some View {
        VStack(spacing: 18) {
            OnbPoli(height: 80)
            questionHead(title, subtitle)
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { opt in
                    optionRow(opt, selected: selection.wrappedValue == opt) {
                        selection.wrappedValue = opt
                    }
                }
            }
            .padding(.top, 2)
            .frame(maxWidth: 360)
        }
    }

    /// A multi-select question screen (hope): pick as many as apply (per the skill's
    /// "allow multi-intent" guidance for goal questions — forcing one felt wrong).
    private func multiSelectStep(title: String, subtitle: String, options: [String],
                                 selection: Binding<Set<String>>) -> some View {
        VStack(spacing: 18) {
            OnbPoli(height: 80)
            questionHead(title, subtitle)
            VStack(spacing: 10) {
                ForEach(options, id: \.self) { opt in
                    optionRow(opt, selected: selection.wrappedValue.contains(opt), multi: true) {
                        if selection.wrappedValue.contains(opt) { selection.wrappedValue.remove(opt) }
                        else { selection.wrappedValue.insert(opt) }
                    }
                }
            }
            .padding(.top, 2)
            .frame(maxWidth: 360)
        }
    }

    /// The worry screen is NOT a pick — its job is to *answer* fears (trust is this
    /// app's bottleneck). So it's an accordion: tap a concern, its answer drops down,
    /// and the parent can read the answer to every one.
    private var worryStep: some View {
        VStack(spacing: 18) {
            OnbPoli(height: 80)
            questionHead("Worried about a Bible app?", "Tap any concern to see our answer.")
            VStack(spacing: 10) {
                ForEach(worryOptions, id: \.self) { w in worryRow(w) }
            }
            .padding(.top, 2)
            .frame(maxWidth: 360)
        }
    }

    private func worryRow(_ w: String) -> some View {
        let open = expandedWorry == w
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { expandedWorry = open ? nil : w }
                worry = w   // remember the last concern opened (pins on the Promise)
            } label: {
                HStack(spacing: 12) {
                    Text(w).font(OnbFont.body(18, .bold)).foregroundStyle(OnbColors.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(OnbColors.brassDeep)
                        .rotationEffect(.degrees(open ? 180 : 0))
                }
                .padding(.vertical, 15).padding(.horizontal, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if open {
                Text(worryAnswer(w))
                    .font(OnbFont.body(16)).foregroundStyle(OnbColors.inkSoft)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 18).padding(.bottom, 15)
                    .transition(.opacity)
            }
        }
        .background(RoundedRectangle(cornerRadius: 16).fill(open ? OnbColors.sand : OnbColors.surface))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(open ? OnbColors.brass : OnbColors.sepiaLine, lineWidth: open ? 3 : 2))
        .accessibilityElement(children: .combine)
        .accessibilityHint(open ? "Collapse answer" : "Expand answer")
    }

    private func worryAnswer(_ w: String) -> String {
        switch w {
        case worryOptions[0]: return "Poli retells in its own words and never quotes Scripture wrong — exact verses come from your family's Bible. Reviewed by pastors, aligned with the Baptist Faith & Message."
        case worryOptions[1]: return "About 10 calm minutes a night. No autoplay, no endless feed, no ads — it ends when the story ends."
        case worryOptions[2]: return "No ads, no chat, no strangers. Nothing is collected about your child, and nothing is used to train any AI."
        case worryOptions[3]: return "Never. When your child asks a big question, Poli hands it back to you — you're the one who answers."
        default: return ""
        }
    }

    private func optionRow(_ label: String, selected: Bool, multi: Bool = false, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: multi ? (selected ? "checkmark.square.fill" : "square")
                                        : (selected ? "largecircle.fill.circle" : "circle"))
                    .font(.system(size: 20))
                    .foregroundStyle(selected ? OnbColors.brassDeep : OnbColors.sepiaLine)
                Text(label).font(OnbFont.body(19, selected ? .bold : .regular))
                    .foregroundStyle(OnbColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 16).padding(.horizontal, 18)
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
            Text("Choosing stories for \(hopesPhrase)… setting a gentle pace…")
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
                    planBullet("sparkles", "Chosen to help \(name) grow in \(hopesPhrase).")
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
            Image(systemName: icon).font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint).frame(width: 26)
            Text(text).font(OnbFont.body(17)).foregroundStyle(OnbColors.ink)
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
        VStack(spacing: 20) {
            OnbPoli(height: 120)
            OnbSpeechBubble(text: "A gentle nudge at story time?")
            Text("One quiet evening reminder. No guilt, no streaks.")
                .font(OnbFont.body(19)).foregroundStyle(OnbColors.ink)
                .multilineTextAlignment(.center).frame(maxWidth: 320)
        }
    }

    private var paywallStep: some View {
        VStack(spacing: 14) {
            glowTitle("Keep walking with \(name)", size: 28)
                .multilineTextAlignment(.center)
            Text("The whole journey, ready when you are.")
                .font(OnbFont.body(18)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center).frame(maxWidth: 320)

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

            VStack(spacing: 4) {
                Image(systemName: "book.fill").font(.system(size: 26))
                    .foregroundStyle(OnbColors.caramel)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(OnbColors.surface))
                    .overlay(Circle().stroke(OnbColors.outline, lineWidth: 3))
                Text("Your Bible · \(translation.displayName)").font(OnbFont.body(13)).foregroundStyle(OnbColors.inkSoft)
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
            Text(text).font(OnbFont.body(16)).foregroundStyle(OnbColors.ink)
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
        childName = ""; age = nil; habit = nil; hopes = []; worry = nil; expandedWorry = nil
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
                                age: age ?? 8),
            translation: translation
        )
    }
}
