import SwiftUI
import BibleStoryCore

/// The parent dashboard — the "Grown-ups" zone reached through the biometric gate.
/// Warm and on-brand (shared `Theme`: parchment, brass, IM Fell English + Atkinson),
/// but a touch more utilitarian than the kid screens: a scrollable stack of clearly
/// labeled cards. It reassures a grown-up about (1) their child's progress, (2) the
/// family's Bible, (3) *how Poli teaches* (the tiered doctrinal stance), and
/// (4) safety/privacy — then hands them a clear way back to the trail.
///
/// Values that have no real store yet are shown as clearly-labeled **sample** data;
/// the active child + translation come from `AppEnvironment`.
struct ParentZoneView: View {
    let env: AppEnvironment

    private var child: ChildProfile? { env.activeChild }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.parchment.ignoresSafeArea()

            ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    header

                    ProgressCard(env: env)
                    ChildProfilesCard(env: env)
                    FamilyBibleCard(env: env).id("familybible")
                    ReadingAccessibilityCard(env: env)
                    QuestionsAskedCard(childName: child?.name ?? "your child")
                    HowPoliTeachesCard()
                    SafetyCard()

                    Text("Poli guides; it never replaces you. The pastor of this\nchild is you.")
                        .font(Theme.hand(17))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                        .padding(.bottom, 8)
                        .accessibilityLabel("Poli guides; it never replaces you. The pastor of this child is you.")
                }
                .padding(.horizontal, 18)
                .padding(.top, 4)
                .padding(.bottom, 28)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .top) { topBar }
            .onAppear {
                // Dev/screenshot: jump to the Bible picker + accessibility cards.
                if ProcessInfo.processInfo.arguments.contains("-uiPreviewParentMid") {
                    proxy.scrollTo("familybible", anchor: .top)
                }
            }
            }
        }
    }

    // MARK: Top bar — a back arrow (returns to the trail) pinned at the very top.

    private var topBar: some View {
        HStack {
            Button { env.exitToChildZone() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left").font(.system(size: 20, weight: .semibold))
                    Text("Trail").font(Theme.body(17, weight: .bold))
                }
                .foregroundStyle(Theme.brassDeep)
                .padding(.vertical, 8).padding(.horizontal, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to the trail")
            .accessibilityHint("Returns to the child's stories")
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Theme.parchment.opacity(0.96))
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 6) {
            Text("GROWN-UPS")
                .font(Theme.mapCaps(15, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Theme.brassDeep)
            Text("Family Dashboard")
                .font(Theme.display(34, weight: .black))
                .foregroundStyle(Theme.ink)
            Text("A quick look at how things are going — and how Poli teaches.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Shared card chrome

/// A utilitarian parchment card with an optional eyebrow icon + title. The workhorse
/// container for the dashboard — warmer than a system `GroupBox`, plainer than the
/// kid screens' framed art.
private struct DashCard<Content: View>: View {
    var icon: String
    var title: String
    var accent: Color = Theme.brassDeep
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(accent.opacity(0.14)))
                Text(title)
                    .font(Theme.display(21, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Theme.parchmentLit)
                .shadow(color: Theme.ink.opacity(0.10), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Theme.sepiaLine.opacity(0.55), lineWidth: 1)
        )
    }
}

// MARK: - Child progress

private struct ProgressCard: View {
    let env: AppEnvironment

    private var child: ChildProfile? { env.activeChild }

    // Real progress, straight from the shared catalog + persisted stores.
    private var storiesTotal: Int { StoryCatalog.all.count }
    private var storiesDone: Int { StoryCatalog.all.filter { env.isStoryComplete($0.id) }.count }
    private var currentStop: String {
        StoryCatalog.all.first { !env.isStoryComplete($0.id) }?.title ?? "Every story explored"
    }
    private var daysExplored: Int { NightsProgress.count }   // stars = days visited (never lost)

    var body: some View {
        DashCard(icon: "figure.child", title: "Explorer's Progress") {
            HStack(spacing: 14) {
                Monogram(name: child?.name)
                VStack(alignment: .leading, spacing: 2) {
                    Text(child?.name ?? "Explorer")
                        .font(Theme.display(24, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    if let age = child?.age {
                        Text("Age \(age)")
                            .font(Theme.body(15))
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Spacer()
            }

            // Trail progress
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("Trail progress")
                        .font(Theme.body(15, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                    Spacer()
                    Text("\(storiesDone) of \(storiesTotal) stories")
                        .font(Theme.body(15))
                        .foregroundStyle(Theme.inkSoft)
                }
                ProgressView(value: Double(storiesDone), total: Double(max(storiesTotal, 1)))
                    .tint(Theme.brass)
                Text(storiesDone < storiesTotal ? "Next up: \(currentStop)" : currentStop)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.top, 2)

            HStack(spacing: 12) {
                StatChip(icon: "star.fill", tint: Theme.brass, value: "\(daysExplored)", label: "days explored")
                StatChip(icon: "book.fill", tint: Theme.brassDeep, value: "\(storiesDone)", label: "stories done")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(child?.name ?? "Explorer")'s progress. \(storiesDone) of \(storiesTotal) stories done. Next up \(currentStop). \(daysExplored) days explored, one star for each.")
    }
}

/// A brass monogram token (child's first initial) — replaces the old emoji avatar.
private struct Monogram: View {
    let name: String?
    private var initial: String { (name?.first.map(String.init) ?? "E").uppercased() }

    var body: some View {
        Text(initial)
            .font(Theme.display(28, weight: .bold))
            .foregroundStyle(Theme.brassDeep)
            .frame(width: 60, height: 60)
            .background(Circle().fill(Theme.sand.opacity(0.5)))
            .overlay(Circle().strokeBorder(Theme.brass.opacity(0.6), lineWidth: 2))
            .accessibilityHidden(true)
    }
}

private struct StatChip: View {
    let icon: String
    let tint: Color
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(value).font(Theme.display(20, weight: .bold)).foregroundStyle(Theme.ink)
                .lineLimit(1)
            Text(label).font(Theme.body(14)).foregroundStyle(Theme.inkSoft)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(Capsule().fill(tint.opacity(0.12)))
        .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1))
    }
}

/// Small italic tag that honestly marks placeholder numbers until a real store lands.
private struct SampleNote: View {
    var body: some View {
        Text("Sample values — live tracking arrives with the story engine.")
            .font(Theme.body(12))
            .foregroundStyle(Theme.inkSoft.opacity(0.85))
            .italic()
    }
}

// MARK: - Family Bible

private struct FamilyBibleCard: View {
    let env: AppEnvironment

    private let columns = [GridItem(.adaptive(minimum: 76), spacing: 10)]

    var body: some View {
        DashCard(icon: "book.closed.fill", title: "Family Bible") {
            Text("Choose the translation Poli reads exact verses from. Poli never words Scripture on its own — every verse card is quoted from the version you pick here.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.inkSoft)

            // Functional picker — tapping a version sets + persists it immediately.
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(BibleTranslation.allCases, id: \.self) { t in
                    let selected = env.translation == t
                    Button { env.setTranslation(t) } label: {
                        Text(t.displayName)
                            .font(Theme.body(15, weight: .bold))
                            .foregroundStyle(selected ? Theme.ink : Theme.inkSoft)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(selected
                                    ? AnyShapeStyle(LinearGradient(colors: [Theme.brassLit, Theme.brass], startPoint: .top, endPoint: .bottom))
                                    : AnyShapeStyle(Theme.sand.opacity(0.4)))
                            )
                            .overlay(Capsule().strokeBorder(selected ? Theme.outline : Theme.sepiaLine.opacity(0.5),
                                                            lineWidth: selected ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Self.fullName(t))
                    .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
                }
            }

            Text(Self.fullName(env.translation))
                .font(Theme.body(14, weight: .bold))
                .foregroundStyle(Theme.sageDeep)
        }
    }

    private static func fullName(_ t: BibleTranslation) -> String {
        switch t {
        case .nirv: "New International Reader's Version"
        case .icb:  "International Children's Bible"
        case .esv:  "English Standard Version"
        case .niv:  "New International Version"
        case .kjv:  "King James Version"
        }
    }
}

// MARK: - How Poli teaches (trust)

private struct HowPoliTeachesCard: View {
    var body: some View {
        DashCard(icon: "hand.raised.fill", title: "How Poli Teaches") {
            Text("Poli is a warm Bible guide for ages 7–9 that faithfully represents our Southern Baptist family (the Baptist Faith & Message). It always knows which kind of question it's being asked:")
                .font(Theme.body(15))
                .foregroundStyle(Theme.inkSoft)

            VStack(spacing: 12) {
                StanceRow(
                    icon: "hand.raised.fill",
                    tint: Theme.brassDeep,
                    verb: "Holds",
                    text: "our core beliefs warmly and confidently — like Jesus is the way to God — and never caves, even when a child pushes back."
                )
                StanceRow(
                    icon: "hands.sparkles.fill",
                    tint: Theme.sageDeep,
                    verb: "Acknowledges",
                    text: "that faithful Christian families differ on some secondary matters — and says so kindly, without declaring a winner."
                )
                StanceRow(
                    icon: "house.fill",
                    tint: Theme.terracotta,
                    verb: "Deflects",
                    text: "the tender, family-owned questions — a loved one's heaven, hard losses, bodies — gently back to you."
                )
            }

            Divider().overlay(Theme.sepiaLine.opacity(0.4))

            VStack(alignment: .leading, spacing: 8) {
                Guarantee("Never quotes Scripture in its own words — exact verses come only from your Bible above.")
                Guarantee("Tells every story with God as the hero, pointing to Jesus — never “try harder to be good.”")
                Guarantee("Never acts as your child's friend, counselor, or pastor. That's you.")
            }
        }
    }
}

private struct StanceRow: View {
    let icon: String
    let tint: Color
    let verb: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(tint.opacity(0.14)))
            VStack(alignment: .leading, spacing: 1) {
                Text(verb)
                    .font(Theme.body(16, weight: .bold))
                    .foregroundStyle(tint)
                Text(text)
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(verb): \(text)")
    }
}

private struct Guarantee: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.brass)
                .padding(.top, 2)
            Text(text)
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Safety & privacy

private struct SafetyCard: View {
    var body: some View {
        DashCard(icon: "lock.shield.fill", title: "Safe & Private", accent: Theme.sageDeep) {
            VStack(spacing: 12) {
                SafetyRow(icon: "iphone", title: "Stays on this device", text: "Poli runs on your iPhone. Your child's questions aren't sent to a server or used to train anything.")
                SafetyRow(icon: "megaphone.slash.fill", title: "No ads, ever", text: "Nothing to buy inside the story, no ads, no tracking.")
                SafetyRow(icon: "person.2.slash.fill", title: "No strangers", text: "No chat, no messages, no other people — just your child, the stories, and Poli.")
                SafetyRow(icon: "faceid", title: "Grown-up gate", text: "This dashboard is locked behind Face ID / passcode, so only you reach it.")
            }
        }
    }
}

private struct SafetyRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.sageDeep)
                .frame(width: 26)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(Theme.body(16, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(text)
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(text)")
    }
}

// MARK: - Child profiles (add / switch explorers)

private struct ChildProfilesCard: View {
    let env: AppEnvironment
    @State private var showingAdd = false

    var body: some View {
        DashCard(icon: "person.2.fill", title: "Explorers") {
            VStack(spacing: 10) {
                ForEach(env.children) { c in
                    let active = env.activeChild?.id == c.id
                    Button { env.selectChild(c) } label: {
                        HStack(spacing: 12) {
                            Monogram(name: c.name)
                                .scaleEffect(0.72)
                                .frame(width: 44, height: 44)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(c.name).font(Theme.body(17, weight: .bold)).foregroundStyle(Theme.ink)
                                Text("Age \(c.age)").font(Theme.body(13)).foregroundStyle(Theme.inkSoft)
                            }
                            Spacer()
                            if active {
                                Text("Active")
                                    .font(Theme.body(13, weight: .bold))
                                    .foregroundStyle(Theme.sageDeep)
                                    .padding(.horizontal, 11).padding(.vertical, 5)
                                    .background(Capsule().fill(Theme.sage.opacity(0.22)))
                            } else {
                                Text("Switch").font(Theme.body(14, weight: .bold)).foregroundStyle(Theme.brassDeep)
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(active ? Theme.brass.opacity(0.10) : Color.clear))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(active ? Theme.brass.opacity(0.5) : Theme.sepiaLine.opacity(0.4), lineWidth: 1))
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(c.name), age \(c.age)\(active ? ", active" : "")")
                }

                Button { showingAdd = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add an explorer")
                    }
                    .font(Theme.body(16, weight: .bold))
                    .foregroundStyle(Theme.brassDeep)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(Theme.sand.opacity(0.4)))
                    .overlay(Capsule().strokeBorder(Theme.sepiaLine.opacity(0.5), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showingAdd) { AddChildSheet(env: env) }
    }
}

private struct AddChildSheet: View {
    let env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var age = 8

    var body: some View {
        NavigationStack {
            Form {
                Section("Explorer") {
                    TextField("Name", text: $name)
                    Stepper("Age \(age)", value: $age, in: 4...12)
                }
            }
            .navigationTitle("Add explorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        env.addChild(ChildProfile(name: trimmed.isEmpty ? "Explorer" : trimmed, age: age))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Reading & accessibility (functional, applied in the reader)

private struct ReadingAccessibilityCard: View {
    let env: AppEnvironment

    var body: some View {
        DashCard(icon: "textformat.size", title: "Reading & Accessibility", accent: Theme.sageDeep) {
            // Text size — a real control that scales the story reader's words.
            VStack(alignment: .leading, spacing: 8) {
                Text("Reading text size").font(Theme.body(15, weight: .bold)).foregroundStyle(Theme.ink)
                HStack(spacing: 8) {
                    ForEach(ReadingSize.allCases, id: \.self) { size in
                        let selected = env.readingSize == size
                        Button { env.setReadingSize(size) } label: {
                            Text(size.label)
                                .font(Theme.body(15, weight: .bold))
                                .foregroundStyle(selected ? Theme.ink : Theme.inkSoft)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(Capsule().fill(selected
                                    ? AnyShapeStyle(LinearGradient(colors: [Theme.brassLit, Theme.brass], startPoint: .top, endPoint: .bottom))
                                    : AnyShapeStyle(Theme.sand.opacity(0.4))))
                                .overlay(Capsule().strokeBorder(selected ? Theme.outline : Theme.sepiaLine.opacity(0.5),
                                                                lineWidth: selected ? 2 : 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(size.label) text")
                        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
                    }
                }
            }

            Divider().overlay(Theme.sepiaLine.opacity(0.4))

            // Read aloud — shows a "Read to me" speaker in the reader (voice output).
            Toggle(isOn: Binding(get: { env.readAloud }, set: { env.setReadAloud($0) })) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Read aloud").font(Theme.body(16, weight: .bold)).foregroundStyle(Theme.ink)
                    Text("Adds a “Read to me” button so Poli reads each page out loud — for pre-readers and reading practice.")
                        .font(Theme.body(13)).foregroundStyle(Theme.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Theme.sageDeep)
        }
    }
}

// MARK: - Questions your child asked

private struct QuestionsAskedCard: View {
    let childName: String

    // Sample transcript — a real store lands with the on-device model. The point it
    // makes is real: the questions Poli sends home are surfaced here for you.
    private let items: [(q: String, deflected: Bool)] = [
        ("Is my hamster in heaven?", true),
        ("Why do we get baptized?", false),
        ("What happens when we die?", true),
        ("Who made God?", false),
    ]

    var body: some View {
        DashCard(icon: "bubble.left.and.text.bubble.right.fill", title: "Questions \(childName) asked") {
            Text("Poli answers what it can and gently sends the tender, family-owned questions home to you. Those are marked “bring home.”")
                .font(Theme.body(15))
                .foregroundStyle(Theme.inkSoft)

            VStack(spacing: 10) {
                ForEach(items, id: \.q) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: item.deflected ? "house.fill" : "checkmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(item.deflected ? Theme.terracotta : Theme.sageDeep)
                            .padding(.top, 2)
                        Text(item.q)
                            .font(Theme.body(15))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 6)
                        if item.deflected {
                            Text("bring home")
                                .font(Theme.body(11, weight: .bold))
                                .foregroundStyle(Theme.terracotta)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(Theme.terracotta.opacity(0.14)))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            SampleNote()
        }
    }
}

#if DEBUG
#Preview {
    let env = AppEnvironment(responder: StubQuestionResponder(), gate: BiometricParentGate())
    env.completeOnboarding(child: ChildProfile(name: "Ruthie", age: 8), translation: .nirv)
    return ParentZoneView(env: env)
}
#endif
