import SwiftUI
import BibleStoryCore

/// The Story Reader (design/story-reader.html): a paged illustrated narrative with
/// drop-caps, a DISTINCT verse card (the exact Scripture, shown as retrieved from
/// the family's Bible — never woven into the retell), and a completion screen with
/// the gospel-centered Christ Connection + the treasure earned at the end.
/// Data-driven from the bundled Content/<id>.json.
struct StoryView: View {
    let env: AppEnvironment
    var storyID: String = "creation"
    /// Explicit exit (pop the navigation path). Reliable even with the nav bar
    /// hidden; falls back to `dismiss()` if not provided.
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    @State private var showComplete = false
    @State private var showAsk = false

    private let story: StoryContent?
    init(env: AppEnvironment, storyID: String = "creation", onClose: (() -> Void)? = nil) {
        self.env = env
        self.storyID = storyID
        self.onClose = onClose
        let loaded = StoryContent.load(storyID)
        self.story = loaded
        // Dev/screenshot deep-links for the later reader states.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-uiPreviewStoryLast") {
            _page = State(initialValue: max(0, (loaded?.pages.count ?? 1) - 1))
        }
        if args.contains("-uiPreviewStoryDone") {
            _showComplete = State(initialValue: true)
        }
    }

    // Palette (from design/build_story_reader.py)
    private let paper   = Color(hex: 0xF6EDD7)
    private let heading = Color(hex: 0x7A4A12)
    private let bodyInk = Color(hex: 0x4A3520)
    private let dropCap = Color(hex: 0xB07E2C)
    private let topInk  = Color(hex: 0x5B4630)
    private let topIcon = Color(hex: 0x7A5A34)
    private let hairline = Color(hex: 0xD8C39A)

    var body: some View {
        ZStack {
            paperBackground
            if let story {
                if showComplete {
                    completionScreen(story)
                        .transition(.opacity)
                } else {
                    readingScreen(story)
                }
            } else {
                Text("Story unavailable")
                    .font(Theme.body(16)).foregroundStyle(Theme.inkSoft)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAsk) {
            AskPoliSheet(env: env).presentationDetents([.medium, .large])
        }
    }

    private var paperBackground: some View {
        paper
            .overlay(
                RadialGradient(colors: [.white.opacity(0.5), .clear],
                               center: UnitPoint(x: 0.3, y: 0.2), startRadius: 0, endRadius: 320)
            )
            .overlay(
                RadialGradient(colors: [Color(hex: 0xB49664, opacity: 0.14), .clear],
                               center: UnitPoint(x: 0.8, y: 0.9), startRadius: 0, endRadius: 300)
            )
            .ignoresSafeArea()
    }

    // MARK: Reading

    private func readingScreen(_ s: StoryContent) -> some View {
        let p = s.pages[page]
        let isLast = page == s.pages.count - 1
        return VStack(spacing: 0) {
            topBar(s, showProgress: true)

            Image(p.assetName)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay(alignment: .top) { Rectangle().fill(hairline).frame(height: 1.5) }
                .overlay(alignment: .bottom) { Rectangle().fill(hairline).frame(height: 1.5) }

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(p.heading)
                        .font(Theme.display(22))
                        .foregroundStyle(heading)
                        .padding(.top, 4)
                    Text(dropCapAttributed(p.text))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                    if isLast { verseCard(s.verse) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 12)
            }

            footer(s, isLast: isLast)
        }
    }

    private func topBar(_ s: StoryContent, showProgress: Bool) -> some View {
        HStack {
            Button { back() } label: {
                Image(systemName: "arrow.left").font(.system(size: 19, weight: .regular))
            }
            .accessibilityLabel("Back")
            Spacer()
            Text(s.title).font(Theme.display(17)).foregroundStyle(topInk)
            Spacer()
            HStack(spacing: 10) {
                Button { showAsk = true } label: {
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                        .font(.system(size: 17))
                }
                .accessibilityLabel("Ask Poli")
                if showProgress { progressDots(total: s.pages.count, current: page) }
            }
        }
        .foregroundStyle(topIcon)
        .padding(.horizontal, 14)
        .frame(height: 46)
    }

    private func footer(_ s: StoryContent, isLast: Bool) -> some View {
        HStack {
            progressDots(total: s.pages.count, current: page)
            Spacer()
            Button { advance(s) } label: {
                HStack(spacing: 7) {
                    Text(isLast ? "FINISH" : "NEXT").font(Theme.mapCaps(15)).tracking(1.5)
                    Image(systemName: "arrow.right").font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(Color(hex: 0x5E3A16))
                .padding(.horizontal, 20).padding(.vertical, 10)
                .background(
                    Capsule().fill(LinearGradient(colors: [Color(hex: 0xF6D062), Color(hex: 0xD19A34)],
                                                  startPoint: .top, endPoint: .bottom))
                )
                .overlay(Capsule().strokeBorder(Color(hex: 0x8A5A22), lineWidth: 1.5))
                .shadow(color: Color(hex: 0x9A6B25), radius: 0, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func progressDots(total: Int, current: Int) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i == current ? Color(hex: 0xB07E2C) : Color(hex: 0xD3BD8E))
                    .frame(width: 7, height: 7)
            }
        }
    }

    // MARK: Verse card (visibly distinct from the retell)

    private func verseCard(_ v: StoryContent.Verse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(v.ref)
                .font(Theme.mapCaps(12)).tracking(2)
                .foregroundStyle(Color(hex: 0x8A5F22))
            Text("“\(v.text)”")
                .font(Theme.hand(16))
                .foregroundStyle(Color(hex: 0x3F2F1C))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 4) {
                Image(systemName: "book.closed.fill").font(.system(size: 9))
                Text("\(v.translation) · shown from your family's Bible")
                    .font(Theme.body(10, weight: .bold))
            }
            .foregroundStyle(Color(hex: 0x8A7350))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(Color(hex: 0xE6D4A8)))
            .overlay(Capsule().strokeBorder(Color(hex: 0xCBB27A), lineWidth: 1))
            .padding(.top, 2)
        }
        .padding(.vertical, 12)
        .padding(.leading, 16)
        .padding(.trailing, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: 0xF0E4C4)))
        .overlay(
            RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: 0xD9C188), lineWidth: 1)
        )
        .overlay(alignment: .leading) {
            LinearGradient(colors: [Color(hex: 0xE7C877), Color(hex: 0xC89A3E)],
                           startPoint: .top, endPoint: .bottom)
                .frame(width: 4)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .shadow(color: Color(hex: 0x5A3C14, opacity: 0.18), radius: 3, x: 0, y: 1)
        .padding(.top, 12)
    }

    // MARK: Completion

    private func completionScreen(_ s: StoryContent) -> some View {
        VStack(spacing: 0) {
            topBar(s, showProgress: false)
            ScrollView {
                VStack(spacing: 6) {
                    RewardMedallion(icon: s.reward.icon)
                        .frame(width: 120, height: 120)
                        .padding(.top, 12)
                    Text("TREASURE EARNED")
                        .font(Theme.body(11, weight: .bold)).tracking(1)
                        .foregroundStyle(Color(hex: 0x8A5F22))
                        .padding(.top, 2)
                    Text(s.reward.name)
                        .font(Theme.display(20)).foregroundStyle(Color(hex: 0x4A3520))
                    Rectangle().fill(Color(hex: 0xCBB27A)).frame(width: 46, height: 2).padding(.top, 6)

                    Text(s.christConnection.heading)
                        .font(Theme.display(22)).foregroundStyle(heading)
                        .padding(.top, 16)
                    Text(s.christConnection.text)
                        .font(Theme.body(14)).foregroundStyle(bodyInk)
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                    Text(s.reward.text)
                        .font(Theme.body(13)).foregroundStyle(Color(hex: 0x8A6A3E))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)

                    Button { close() } label: {
                        HStack(spacing: 7) {
                            Image(systemName: "location.north.circle.fill").font(.system(size: 14))
                            Text("BACK TO THE MAP").font(Theme.mapCaps(15)).tracking(1.5)
                        }
                        .foregroundStyle(Color(hex: 0x5E3A16))
                        .padding(.horizontal, 22).padding(.vertical, 11)
                        .background(
                            Capsule().fill(LinearGradient(colors: [Color(hex: 0xF6D062), Color(hex: 0xD19A34)],
                                                          startPoint: .top, endPoint: .bottom))
                        )
                        .overlay(Capsule().strokeBorder(Color(hex: 0x8A5A22), lineWidth: 1.5))
                        .shadow(color: Color(hex: 0x9A6B25), radius: 0, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 16)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 22)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: Actions

    private func advance(_ s: StoryContent) {
        if page < s.pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.22)) { page += 1 }
        } else {
            withAnimation(.easeInOut(duration: 0.3)) { showComplete = true }
        }
    }

    private func back() {
        if showComplete {
            withAnimation { showComplete = false }
        } else if page > 0 {
            withAnimation(.easeInOut(duration: 0.22)) { page -= 1 }
        } else {
            close()
        }
    }

    /// Leave the reader (back to the map).
    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    /// Illuminated initial + body: the first glyph in the display serif/gold, the
    /// rest in the body face (a warm stand-in for the CSS drop-cap).
    private func dropCapAttributed(_ text: String) -> AttributedString {
        var out = AttributedString()
        if let first = text.first {
            var cap = AttributedString(String(first))
            cap.font = Theme.display(30)
            cap.foregroundColor = dropCap
            out.append(cap)
        }
        var rest = AttributedString(String(text.dropFirst()))
        rest.font = Theme.body(15)
        rest.foregroundColor = bodyInk
        out.append(rest)
        return out
    }
}

/// The completion reward token: a gold medallion with a ray-burst and the story's
/// emblem (the compass rose reuses the map's vector `CompassRose`).
struct RewardMedallion: View {
    var icon: String = "compass"

    var body: some View {
        ZStack {
            RayBurst().fill(Color(hex: 0xE7C877)).opacity(0.5)
                .frame(width: 150, height: 150)
            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xFBE7A6), Color(hex: 0xD9A94E)],
                                     center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: 60))
                .frame(width: 96, height: 96)
                .overlay(Circle().strokeBorder(Color(hex: 0xB07E2C), lineWidth: 3))
                .overlay(Circle().strokeBorder(Color(hex: 0xD9A94E, opacity: 0.25), lineWidth: 6).padding(-6))
                .shadow(color: Color(hex: 0x5A3C14, opacity: 0.35), radius: 4, x: 0, y: 4)
            emblem
        }
    }

    @ViewBuilder private var emblem: some View {
        switch icon {
        case "compass":
            CompassRose(color: Color(hex: 0x5E3A16)).frame(width: 54, height: 54)
        case "waves":
            Image(systemName: "water.waves").font(.system(size: 40, weight: .bold)).foregroundStyle(Color(hex: 0x5E3A16))
        case "heart":
            Image(systemName: "heart.fill").font(.system(size: 40)).foregroundStyle(Color(hex: 0x5E3A16))
        case "dove":
            Image(systemName: "bird.fill").font(.system(size: 40)).foregroundStyle(Color(hex: 0x5E3A16))
        default:
            Image(systemName: "star.fill").font(.system(size: 40)).foregroundStyle(Color(hex: 0x5E3A16))
        }
    }
}

/// A 12-spoke ray burst behind the reward medallion.
private struct RayBurst: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOuter = min(rect.width, rect.height) / 2
        let rInner = rOuter * 0.62
        let halfW = rOuter * 0.02 + 1
        for k in 0..<12 {
            let a = CGFloat(k) * (.pi * 2 / 12)
            let dir = CGVector(dx: cos(a), dy: sin(a))
            let perp = CGVector(dx: -dir.dy, dy: dir.dx)
            let tip = CGPoint(x: c.x + dir.dx * rOuter, y: c.y + dir.dy * rOuter)
            let b1 = CGPoint(x: c.x + dir.dx * rInner + perp.dx * halfW,
                             y: c.y + dir.dy * rInner + perp.dy * halfW)
            let b2 = CGPoint(x: c.x + dir.dx * rInner - perp.dx * halfW,
                             y: c.y + dir.dy * rInner - perp.dy * halfW)
            p.move(to: tip); p.addLine(to: b1); p.addLine(to: b2); p.closeSubpath()
        }
        return p
    }
}
