import SwiftUI
import AVFoundation
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
    @State private var synth = AVSpeechSynthesizer()   // read-aloud (parent setting)

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
            topBar(s)
            progressStrip(total: s.pages.count, current: page)

            // Fixed art band. `.id(page)` gives each page's illustration its own view
            // identity so switching pages SWAPS cleanly instead of interpolating between
            // two differently-cropped images (which looked like the art resizing/animating
            // and shifted everything below it). `.allowsHitTesting(false)` keeps the
            // scaledToFill overflow from stealing taps from the top bar.
            // Fill the art INSIDE a fixed, width-bounded box. A bare `scaledToFill` image
            // reports its (aspect-driven) intrinsic width, which is wider than the screen
            // and pushed the whole reading column past both edges. Color.clear has no
            // intrinsic width, so it takes exactly the screen width and clips the fill.
            Color.clear
                .frame(height: 240)
                .overlay { Image(p.assetName).resizable().scaledToFill() }
                .clipped()
                .overlay(alignment: .top) { Rectangle().fill(hairline).frame(height: 1.5) }
                .overlay(alignment: .bottom) { Rectangle().fill(hairline).frame(height: 1.5) }
                .allowsHitTesting(false)
                .id(page)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(p.heading)
                            .font(Theme.display(30 * env.readingSize.scale))
                            .foregroundStyle(heading)
                        Spacer(minLength: 8)
                        if env.readAloud { readAloudButton(p.text) }
                    }
                    Text(dropCapAttributed(p.text, scale: env.readingSize.scale))
                        .lineSpacing(7 * env.readingSize.scale)
                        .fixedSize(horizontal: false, vertical: true)
                    if isLast { verseCard(s.verse) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 22)
            }

            footer(s, isLast: isLast)
        }
    }

    private func topBar(_ s: StoryContent) -> some View {
        HStack(spacing: 8) {
            // Always returns straight to the map (one tap, from any page or the
            // finish screen). Page-to-page navigation is the progress bar + NEXT.
            Button { close() } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold))
                    Text("Map").font(Theme.body(16, weight: .bold))
                }
                .padding(.horizontal, 10)
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to the map")
            Spacer()
            Text(s.title)
                .font(Theme.display(24)).foregroundStyle(topInk)
                .lineLimit(1).minimumScaleFactor(0.6)
            Spacer()
            // Tap Poli to ask a question out loud (opens the Ask-Poli sheet).
            // Larger than the other controls so it's easy for young readers to see + hit.
            Button { showAsk = true } label: {
                PoliImage(pose: .waving, size: 60)
                    .frame(width: 60, height: 60)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ask Poli")
        }
        .foregroundStyle(topIcon)
        .padding(.horizontal, 12)
        .frame(height: 48)
    }

    private func footer(_ s: StoryContent, isLast: Bool) -> some View {
        HStack {
            Spacer()
            Button { advance(s) } label: {
                HStack(spacing: 8) {
                    Text(isLast ? "FINISH" : "NEXT").font(Theme.mapCaps(20)).tracking(1.5)
                    Image(systemName: "arrow.right").font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(Color(hex: 0x5E3A16))
                .padding(.horizontal, 24).padding(.vertical, 13)
                .background(
                    Capsule().fill(LinearGradient(colors: [Color(hex: 0xF6D062), Color(hex: 0xD19A34)],
                                                  startPoint: .top, endPoint: .bottom))
                )
                .overlay(Capsule().strokeBorder(Color(hex: 0x8A5A22), lineWidth: 1.5))
                .shadow(color: Color(hex: 0x5A3C14, opacity: 0.28), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    /// Slim treasure-map progress: one refined capsule per page, filled (brass) up
    /// to the current page, plus a small count. Sits tight under the top bar. Each
    /// segment is its OWN tap target — tapping a segment jumps straight to that page
    /// (seek forward or back), alongside the back arrow.
    private func progressStrip(total: Int, current: Int) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                ForEach(0..<total, id: \.self) { i in
                    Capsule()
                        .fill(i <= current
                              ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0xF6D062), Color(hex: 0xD19A34)],
                                                             startPoint: .top, endPoint: .bottom))
                              : AnyShapeStyle(Color(hex: 0xEBDCB4)))
                        .frame(height: 5)
                        .overlay {
                            if i > current {
                                Capsule().strokeBorder(Color(hex: 0xCBB27A), lineWidth: 1)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)          // tall, easy tap target per page
                        .contentShape(Rectangle())
                        .onTapGesture { seek(to: i) }
                        .accessibilityLabel("Go to page \(i + 1) of \(total)")
                        .accessibilityAddTraits(i == current ? [.isButton, .isSelected] : .isButton)
                }
            }
            Text("\(current + 1)/\(total)")
                .font(Theme.mapCaps(11)).tracking(1)
                .foregroundStyle(Color(hex: 0x8A5F22))
        }
        .padding(.horizontal, 22)
        .padding(.top, 2)
    }

    /// Jump the reader to a specific page (progress-bar seek).
    private func seek(to index: Int) {
        guard index != page else { return }
        stopSpeaking()
        page = index        // instant, clean swap
    }

    // MARK: Verse card (visibly distinct from the retell)

    private func verseCard(_ v: StoryContent.Verse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(v.ref)
                .font(Theme.mapCaps(15)).tracking(2)
                .foregroundStyle(Color(hex: 0x8A5F22))
            Text("“\(v.text)”")
                .font(Theme.hand(22))
                .foregroundStyle(Color(hex: 0x3F2F1C))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 4) {
                Image(systemName: "book.closed.fill").font(.system(size: 11))
                Text("\(v.translation) · shown from your family's Bible")
                    .font(Theme.body(12, weight: .bold))
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
            topBar(s)
            ScrollView {
                VStack(spacing: 8) {
                    RewardMedallion(icon: s.reward.icon)
                        .frame(width: 132, height: 132)
                        .padding(.top, 12)
                    Text("TREASURE EARNED")
                        .font(Theme.body(14, weight: .bold)).tracking(1)
                        .foregroundStyle(Color(hex: 0x8A5F22))
                        .padding(.top, 2)
                    Text(s.reward.name)
                        .font(Theme.display(26)).foregroundStyle(Color(hex: 0x4A3520))
                    Rectangle().fill(Color(hex: 0xCBB27A)).frame(width: 46, height: 2).padding(.top, 6)

                    // Nights together — a star lit tonight (grace, not guilt: only grows).
                    NightSkyBadge(count: NightsProgress.count).padding(.top, 10)
                    if let m = NightsProgress.milestone(NightsProgress.count) {
                        Text(m)
                            .font(Theme.body(14, weight: .bold))
                            .foregroundStyle(Color(hex: 0x8A5F22))
                            .padding(.top, 2)
                    }

                    Text(s.christConnection.heading)
                        .font(Theme.display(30)).foregroundStyle(heading)
                        .padding(.top, 16)
                    Text(s.christConnection.text)
                        .font(Theme.body(19)).foregroundStyle(bodyInk)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                    Text(s.reward.text)
                        .font(Theme.body(17)).foregroundStyle(Color(hex: 0x8A6A3E))
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)

                    Button { close() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "location.north.circle.fill").font(.system(size: 18))
                            Text("BACK TO THE MAP").font(Theme.mapCaps(20)).tracking(1.5)
                        }
                        .foregroundStyle(Color(hex: 0x5E3A16))
                        .padding(.horizontal, 26).padding(.vertical, 14)
                        .background(
                            Capsule().fill(LinearGradient(colors: [Color(hex: 0xF6D062), Color(hex: 0xD19A34)],
                                                          startPoint: .top, endPoint: .bottom))
                        )
                        .overlay(Capsule().strokeBorder(Color(hex: 0x8A5A22), lineWidth: 1.5))
                        .shadow(color: Color(hex: 0x5A3C14, opacity: 0.28), radius: 5, x: 0, y: 3)
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
        stopSpeaking()
        if page < s.pages.count - 1 {
            page += 1        // instant, clean swap (no size-morph animation)
        } else {
            NightsProgress.recordTonight()   // light tonight's star (grace, not guilt — only ever grows)
            env.markStoryComplete(storyID)   // unlock the next stop on the trail
            withAnimation(.easeInOut(duration: 0.3)) { showComplete = true }
        }
    }

    private func back() {
        stopSpeaking()
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
        stopSpeaking()
        if let onClose { onClose() } else { dismiss() }
    }

    /// Illuminated initial + body: the first glyph in the display serif/gold, the
    /// rest in the body face (a warm stand-in for the CSS drop-cap).
    private func dropCapAttributed(_ text: String, scale: Double = 1) -> AttributedString {
        var out = AttributedString()
        if let first = text.first {
            var cap = AttributedString(String(first))
            cap.font = Theme.display(56 * scale)   // illuminated initial
            cap.foregroundColor = dropCap
            out.append(cap)
        }
        var rest = AttributedString(String(text.dropFirst()))
        rest.font = Theme.body(22 * scale)         // big, kid-legible narrative
        rest.foregroundColor = bodyInk
        out.append(rest)
        return out
    }

    // MARK: Read aloud (voice output — enabled from the parent dashboard)

    private func readAloudButton(_ text: String) -> some View {
        Button { speak(text) } label: {
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2.fill").font(.system(size: 13, weight: .bold))
                Text("Read to me").font(Theme.body(14, weight: .bold))
            }
            .foregroundStyle(Color(hex: 0x5E3A16))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(Color(hex: 0xE6D4A8)))
            .overlay(Capsule().strokeBorder(Color(hex: 0xCBB27A), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Read this page aloud")
    }

    /// Speak the page with a gentle, slightly-slow child-friendly voice.
    private func speak(_ text: String) {
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.rate = 0.44
        u.pitchMultiplier = 1.05
        u.postUtteranceDelay = 0.1
        synth.speak(u)
    }

    private func stopSpeaking() { synth.stopSpeaking(at: .immediate) }
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
