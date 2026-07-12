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
        ZStack {
            Theme.parchment.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    header

                    ProgressCard(child: child)
                    FamilyBibleCard(translation: env.translation)
                    HowPoliTeachesCard()
                    SafetyCard()

                    doneButton
                        .padding(.top, 4)

                    Text("Poli guides; it never replaces you. The pastor of this\nchild is you.")
                        .font(Theme.hand(17))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                        .padding(.bottom, 8)
                        .accessibilityLabel("Poli guides; it never replaces you. The pastor of this child is you.")
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 28)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
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
        .padding(.top, 8)
        .accessibilityElement(children: .combine)
    }

    // MARK: Done button

    private var doneButton: some View {
        Button {
            env.exitToChildZone()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.backward")
                Text("Back to the trail")
            }
            .font(Theme.body(19, weight: .bold))
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                Capsule(style: .continuous)
                    .fill(LinearGradient(colors: [Theme.brassLit, Theme.brass], startPoint: .top, endPoint: .bottom))
            )
            .overlay(Capsule(style: .continuous).strokeBorder(Theme.outline, lineWidth: 2.5))
            .shadow(color: Theme.brass.opacity(0.4), radius: 10, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back to the trail")
        .accessibilityHint("Returns to the child's stories")
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
    let child: ChildProfile?

    // Sample trail state mirrors the child-zone map (2 stops done, 1 active, 1 locked).
    // Wire these to a real progress store when one exists.
    private let storiesDone = 2
    private let storiesTotal = 4
    private let currentStop = "Jesus & the Children"
    private let stars = 6
    private let streakDays = 3

    var body: some View {
        DashCard(icon: "figure.child", title: "Explorer's Progress") {
            HStack(spacing: 14) {
                Text(child?.avatar ?? "🦊")
                    .font(.system(size: 40))
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Theme.sand.opacity(0.5)))
                    .overlay(Circle().strokeBorder(Theme.brass.opacity(0.6), lineWidth: 2))
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
                ProgressView(value: Double(storiesDone), total: Double(storiesTotal))
                    .tint(Theme.brass)
                Text("Now exploring: \(currentStop)")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.top, 2)

            HStack(spacing: 12) {
                StatChip(icon: "star.fill", tint: Theme.brass, value: "\(stars)", label: "stars")
                StatChip(icon: "flame.fill", tint: Theme.terracotta, value: "\(streakDays)", label: "day streak")
            }

            SampleNote()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(child?.name ?? "Explorer")'s progress. \(storiesDone) of \(storiesTotal) stories done. Now exploring \(currentStop). \(stars) stars, \(streakDays) day streak. Sample values.")
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
            Text(label).font(Theme.body(14)).foregroundStyle(Theme.inkSoft)
        }
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
    let translation: BibleTranslation

    var body: some View {
        DashCard(icon: "book.closed.fill", title: "Family Bible") {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(translation.displayName)
                        .font(Theme.display(26, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text(Self.fullName(translation))
                        .font(Theme.body(14))
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
                Text("In use")
                    .font(Theme.body(13, weight: .bold))
                    .foregroundStyle(Theme.sageDeep)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Capsule().fill(Theme.sage.opacity(0.22)))
            }
            Text("Every exact verse Poli shows is read from this translation — Poli never words Scripture on its own. You can change the family translation in Settings.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.inkSoft)
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

#if DEBUG
#Preview {
    let env = AppEnvironment(responder: StubQuestionResponder(), gate: BiometricParentGate())
    env.completeOnboarding(child: ChildProfile(name: "Ruthie", age: 8, avatar: "🦊"), translation: .nirv)
    return ParentZoneView(env: env)
}
#endif
