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
        case welcome, founder, storyIntro,
             name, age, bible,
             promise, askDemo, notify,
             paywall, finale
    }

    /// The quiz steps that show the "filling map path" progress dots.
    private static let quizSteps: [Step] = [.name, .age, .bible]

    @State private var step: Step = OnboardingView.startStep

    /// DEBUG-only deep-link: `ONB_STEP=<rawValue>` jumps to a step for screenshots
    /// (age = 5). Unset ⇒ .welcome. Compiled out of Release.
    private static var startStep: Step {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["ONB_STEP"],
           let n = Int(raw), let s = Step(rawValue: n) { return s }
        #endif
        return .welcome
    }
    @State private var childName = ""
    @State private var age: Int? = nil
    @State private var translation: BibleTranslation = .nirv
    @State private var annualPlan = true
    @State private var showStory = false
    /// Which sample question is expanded in the "Try Ask Poli" demo (nil = none yet).
    @State private var demoPick: Int? = nil
    /// Which promise row is expanded in the "Our promises" accordion (nil = none).
    @State private var expandedPromise: String? = nil

    /// The child's display name once entered; a warm fallback before then.
    private var name: String {
        let trimmed = childName.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? "your explorer" : trimmed
    }
    private var possessive: String { "\(name)'s" }

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
                go(to: .name)
            }, exitContext: .onboarding)
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
                #if DEBUG
                // Dev only (never ships): jump straight past onboarding to the map.
                Button { complete() } label: {
                    HStack(spacing: 3) {
                        Text("Skip").font(OnbFont.body(14, .bold))
                        Image(systemName: "arrow.right").font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(OnbColors.inkSoft)
                    .padding(.horizontal, 12).frame(height: 34)
                    .background(Capsule().fill(OnbColors.sand.opacity(0.5)))
                    .overlay(Capsule().strokeBorder(OnbColors.sepiaLine, lineWidth: 1.5))
                }
                .accessibilityLabel("Skip onboarding (dev)")
                #endif
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
                primary("Play a story", icon: "arrow.right") { showStory = true }
                ghost("Maybe later") { go(to: .name) }
            case .name:
                primary("Continue ✦") { go(to: .age) }
                    .disabled(childName.trimmingCharacters(in: .whitespaces).isEmpty)
            case .age:
                primary("Continue ✦") { go(to: .bible) }.disabled(age == nil)
            case .bible:
                primary("Continue ✦") { go(to: .promise) }
            case .promise:
                primary("I trust this — continue ✦") { go(to: .askDemo) }
            case .askDemo:
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

    private func primary(_ title: String, icon: String? = nil, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            if let icon {
                HStack(spacing: 8) { Text(title); Image(systemName: icon) }
            } else {
                Text(title)
            }
        }
        .buttonStyle(OnbPrimaryButtonStyle())
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
        case .name:       nameStep
        case .age:        ageStep
        case .bible:      bibleStep
        case .promise:    promiseStep
        case .askDemo:    askDemoStep
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
            Text("Built on the Baptist Faith & Message · No ads · No chat")
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
            OnbSpeechBubble(text: "I'll read you the very first story — \u{201C}Creation.\u{201D} ✦")
        }
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

    private var promiseStep: some View {
        VStack(spacing: 16) {
            eyebrow("Our promise to you")
            OnbPoli(height: 88)
            card {
                VStack(alignment: .leading, spacing: 16) {
                    OnbPromiseRow(icon: "book.closed.fill", title: "Told faithfully.",
                                  detail: "Poli retells in its own words and never quotes Scripture wrong — real verses come from your \(translation.displayName).")
                    OnbPromiseRow(icon: "checkmark.seal.fill", title: "Sound doctrine.",
                                  detail: "Written to align with the Baptist Faith & Message (2000).")
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

    // MARK: Comes home to you (the DEFLECT list)

    /// One kind of tender question Poli gently redirects to the grown-up.
    private let sendHomeItems: [(icon: String, title: String, detail: String, tint: Color)] = [
        ("cloud.fill", "\u{201C}Where is grandma now?\u{201D}",
         "Death, heaven, and grief — held with you, not a screen.", OnbColors.caramel),
        ("bandage.fill", "\u{201C}Why did someone I love get sick?\u{201D}",
         "Suffering and loss, in your family's own words.", OnbColors.terracotta),
        ("figure.child", "Bodies, growing up, and hard family moments",
         "Tender and personal — yours to walk through together.", OnbColors.sage),
        ("person.fill.questionmark", "\u{201C}Is my friend saved?\u{201D}",
         "Where a specific person stands with God is never Poli's to say.", OnbColors.brassDeep),
        ("building.columns.fill", "The specifics your church teaches",
         "The details your family and church pass on — kept with you.", OnbColors.brass),
    ]

    private var sendHomeStep: some View {
        VStack(spacing: 16) {
            eyebrow("What comes home to you")
            OnbPoli(height: 88, pose: .pointing)
            glowTitle("The big questions stay yours", size: 26)
                .multilineTextAlignment(.center)
            Text("Poli answers what it can tell faithfully. But some wonderings belong in your arms, not an app's. Here are the ones Poli will gently hand back to you:")
                .font(OnbFont.body(15)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center).lineSpacing(3).frame(maxWidth: 340)
            card {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(sendHomeItems.enumerated()), id: \.offset) { _, item in
                        OnbPromiseRow(icon: item.icon, title: item.title,
                                      detail: item.detail, tint: item.tint)
                    }
                }
            }
            OnbSpeechBubble(text: "For these, I'll say: \u{201C}What a wonderful question to bring to your grown-up.\u{201D} \u{2726}")
                .padding(.top, 4)
        }
    }

    // MARK: Try Ask Poli (interactive 3-tier demo)

    /// Scripted sample Q&A — a preview of the three behaviors (hold / acknowledge /
    /// deflect). NOT the real model; hardcoded to model the stance faithfully.
    private let demoQAs: [(q: String, tag: String, tagIcon: String, tint: Color, reply: String)] = [
        ("Is Jesus really God?",
         "Poli holds this close", "heart.fill", OnbColors.brassDeep,
         "Yes — with all my heart! The Bible tells us Jesus is God's own Son, fully God and fully man, who loves you more than you can imagine. \u{2726}"),
        ("When should someone be baptized?",
         "Faithful families differ", "arrow.triangle.branch", OnbColors.sage,
         "That's a good one! Christian families who love the Bible answer this a little differently. It's a beautiful thing to talk over with your grown-up and your church."),
        ("Is my hamster in heaven?",
         "This comes home to you", "house.fill", OnbColors.terracotta,
         "Oh, that's a tender question. Let's carry this one to your grown-up — it's exactly the kind of big wondering that's best to share together. \u{1F49B}"),
    ]

    private var askDemoStep: some View {
        VStack(spacing: 14) {
            eyebrow("Try it · a quick preview")
            OnbPoli(height: 84, pose: .waving)
            glowTitle("See how Poli answers", size: 26)
                .multilineTextAlignment(.center)
            Text("Tap a question to see how Poli would respond. It answers what it can tell faithfully — and sends the tender ones home to you.")
                .font(OnbFont.body(15)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center).lineSpacing(3).frame(maxWidth: 340)
            VStack(spacing: 12) {
                ForEach(Array(demoQAs.enumerated()), id: \.offset) { i, qa in
                    demoQuestionRow(index: i, qa: qa)
                }
            }
            .padding(.top, 4)
            .frame(maxWidth: 360)
            Text("This is a preview — not a real chat. It shows how Poli is built to respond.")
                .font(OnbFont.body(12)).foregroundStyle(OnbColors.inkSoft)
                .multilineTextAlignment(.center).padding(.top, 2)
        }
    }

    @ViewBuilder
    private func demoQuestionRow(index i: Int,
                                 qa: (q: String, tag: String, tagIcon: String, tint: Color, reply: String)) -> some View {
        let open = demoPick == i
        VStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    demoPick = open ? nil : i
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(open ? OnbColors.brassDeep : OnbColors.sepiaLine)
                    Text("\u{201C}\(qa.q)\u{201D}")
                        .font(OnbFont.body(16, open ? .bold : .regular))
                        .foregroundStyle(OnbColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Image(systemName: open ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(OnbColors.inkSoft)
                }
                .padding(.vertical, 13).padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(open ? OnbColors.sand : OnbColors.surface))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(open ? OnbColors.brass : OnbColors.sepiaLine, lineWidth: open ? 3 : 2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Sample question: \(qa.q)")
            .accessibilityAddTraits(.isButton)

            if open {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: qa.tagIcon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(OnbColors.ctaInk)
                        Text(qa.tag.uppercased())
                            .font(OnbFont.caps(11)).tracking(1.5)
                            .foregroundStyle(OnbColors.ctaInk)
                    }
                    .padding(.vertical, 5).padding(.horizontal, 12)
                    .background(Capsule().fill(qa.tint.opacity(0.9)))
                    .overlay(Capsule().stroke(OnbColors.outline, lineWidth: 1.5))

                    HStack(alignment: .top, spacing: 10) {
                        OnbPoli(height: 48, pose: .waving)
                        Text(qa.reply)
                            .font(OnbFont.hand(19)).foregroundStyle(OnbColors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 18).fill(OnbColors.surfaceRead))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(qa.tint.opacity(0.55), lineWidth: 2))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Poli, \(qa.tag): \(qa.reply)")
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
