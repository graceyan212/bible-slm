import SwiftUI
import BibleStoryCore

enum HomeRoute: Hashable { case story(String), compass }

/// The child-zone home — "The Expedition" treasure map. A parchment field ringed
/// by an ornate rope border, an illuminated banner, and framed story "stops"
/// strung along a winding rope up to the glowing active lesson, with Poli the
/// compass mascot pointing at START LESSON. A bottom map tab bar switches sections.
struct HomeView: View {
    let env: AppEnvironment
    @State private var path: [HomeRoute] = []
    @State private var tab: MapTab = .map
    /// Dev/screenshot hook: start the map scrolled to the bottom (see `-uiPreviewMapBottom`).
    private let previewMapBottom: Bool

    init(env: AppEnvironment) {
        self.env = env
        // Dev/screenshot deep-links (see BibleStoryApp `-uiPreviewChild`).
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-uiPreviewTreasures") { _tab = State(initialValue: .treasures) }
        if args.contains("-uiPreviewStories") { _tab = State(initialValue: .stories) }
        // Jump straight to the Grown-ups TAB, bypassing the biometric gate for
        // screenshots (dev only — the real tap always runs the gate; see enterGrownUps).
        if args.contains("-uiPreviewGrownUps") { _tab = State(initialValue: .grownUps) }
        if args.contains("-uiPreviewStory") || args.contains("-uiPreviewOnbStory") {
            _path = State(initialValue: [.story("creation")])
        }
        previewMapBottom = args.contains("-uiPreviewMapBottom")
    }

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Group {
                    switch tab {
                    case .map:       expeditionMap
                    case .stories:   StoriesView(onOpen: { path.append(.story($0)) }, completed: env.completedStoryIDs).padding(.bottom, 62)
                    case .treasures: TreasuresView(env: env).padding(.bottom, 62)
                    // Grown-ups is a real tab now (the bottom nav bar stays visible).
                    // The gate ran before we got here (enterGrownUps); "back" just
                    // returns to the Map tab rather than blanking to a phase change.
                    case .grownUps:  ParentZoneView(env: env, onBack: { selectTab(.map) }).padding(.bottom, 62)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 5-slot bar: Map · Stories · [Poli center → Ask] · Treasures · Grown-ups.
                // Carved-wood plank on every tab. Ask Poli pushes CompassView (no bar);
                // Grown-ups authenticates, then selects the gated dashboard tab.
                MapTabBar(selection: $tab, transparent: tab == .map,
                          onPoli: { path.append(.compass) },
                          onGrownUps: { enterGrownUps() },
                          bottomSafeInset: proxy.safeAreaInsets.bottom)
            }
            .background(Theme.parchment.ignoresSafeArea())
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .story(let id): StoryView(env: env, storyID: id, onClose: pop)
                case .compass: CompassView(env: env, onClose: pop)
                }
            }
            }
        }
    }

    /// Pop one level off the navigation path. Explicit path mutation is reliable
    /// even when a pushed screen hides the nav bar (where `dismiss()` can no-op).
    private func pop() { if !path.isEmpty { path.removeLast() } }

    private func selectTab(_ t: MapTab) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { tab = t }
    }

    /// Tapping the Grown-ups tab: authenticate (biometric / passcode) WITHOUT leaving
    /// the child phase, then switch to the Grown-ups tab so the nav bar stays visible.
    /// On cancel/failure we stay on the current tab. Re-tapping while already there is
    /// a no-op (no re-prompt). This replaces the old phase=.parent full-screen route.
    private func enterGrownUps() {
        guard tab != .grownUps else { return }
        Task {
            if await env.authenticateForParent() { selectTab(.grownUps) }
        }
    }

    // MARK: The framed treasure-map screen (the "Map" tab)

    /// Aspect (h / w) of the tall ExpeditionMap art (656 × 5900) — the map canvas
    /// is this many screens-wide tall, so the trail scrolls vertically.
    private static let mapAspect: CGFloat = 5900.0 / 656.0
    /// Story stops ride the winding trail between these vertical fractions of the
    /// tall map (mountains sit above the first stop; the compass + chest destination
    /// sits below the last), alternating left/right of centre.
    private static let trailTopFraction: CGFloat = 0.045
    private static let trailBottomFraction: CGFloat = 0.82

    /// Centres for each stop down the winding trail. Alternates sides so the rope
    /// snakes; spreads evenly no matter how many stories the catalog holds.
    private func trailPoints(count: Int, w: CGFloat, mapH: CGFloat) -> [CGPoint] {
        (0..<count).map { i in
            let t = count <= 1
                ? Self.trailTopFraction
                : Self.trailTopFraction + (Self.trailBottomFraction - Self.trailTopFraction) * CGFloat(i) / CGFloat(count - 1)
            let x = i.isMultiple(of: 2) ? w * 0.34 : w * 0.65
            return CGPoint(x: x, y: mapH * t)
        }
    }

    private var expeditionMap: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let mapH = w * Self.mapAspect
            let stopW = w * 0.45
            let stops = StoryCatalog.all
            let points = trailPoints(count: stops.count, w: w, mapH: mapH)

            // Only the map content scrolls; the wood nav bar stays pinned (it is a
            // sibling overlay in HomeView's bottom-aligned ZStack).
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Buffer so the pinned "The Expedition" header never covers the top stop.
                    Color.clear.frame(height: 88)
                    ZStack(alignment: .top) {
                        PaintedMapBackdrop()
                            .frame(width: w, height: mapH)
                            .clipped()

                        // Faint rope trail connecting the stops down the map.
                        RopeTrail(points: points)
                            .frame(width: w, height: mapH)
                            .allowsHitTesting(false)

                        // Story stops, strung down the winding trail (data-driven —
                        // add to StoryCatalog and a new stop appears here).
                        ForEach(Array(stops.enumerated()), id: \.element.id) { index, story in
                            let state = StoryCatalog.state(for: index, completed: env.completedStoryIDs)
                            PaintedStoryFrame(coverAsset: story.cover, title: story.title, state: state) {
                                if state != .locked { path.append(.story(story.id)) }
                            }
                            .frame(width: stopW)
                            .position(points[index])
                        }
                    }
                    .frame(width: w, height: mapH)

                    // Bottom breathing room so the last stop / destination clears
                    // the pinned wood nav bar.
                    Color.clear.frame(height: 96)
                }
            }
            .defaultScrollAnchor(previewMapBottom ? .bottom : .top)
            .ignoresSafeArea()
        }
        .ignoresSafeArea()
        // Pinned page title, consistent with the other tabs. It rides ABOVE the
        // scrolling map (an overlay, so it never scrolls away), with a soft
        // parchment scrim behind it so it stays legible over the painted art.
        .overlay(alignment: .top) {
            ScreenTitle("The Expedition", subtitle: "Follow the trail, stop by stop.")
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity)
                .background(
                    Theme.parchment.opacity(0.98)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Theme.sepiaLine.opacity(0.55)).frame(height: 1)
                        }
                        .ignoresSafeArea(edges: .top)
                )
        }
    }
}

/// The big pressable brass "START LESSON" candy button (sticker outline + hard shadow).
struct StartLessonButton: View {
    let action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            Text("START LESSON")
                .font(Theme.display(22, weight: .black))
                .tracking(1)
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule(style: .continuous)
                        .fill(LinearGradient(colors: [Theme.brassLit, Theme.brass], startPoint: .top, endPoint: .bottom))
                )
                .overlay(Capsule(style: .continuous).strokeBorder(Theme.outline, lineWidth: 3))
                .shadow(color: Theme.brass.opacity(0.55), radius: 18, x: 0, y: 0)
                .offset(y: pressed ? 4 : 0)
                .shadow(color: Theme.outline, radius: 0, x: 0, y: pressed ? 2 : 6)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.08)) { pressed = true } }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.12)) { pressed = false } }
        )
        .accessibilityLabel("Start lesson")
    }
}

/// A thick twisted rope connecting the map stops (caramel body + lighter twist highlight).
struct RopeTrail: View {
    let points: [CGPoint]

    var body: some View {
        ZStack {
            ropePath
                .stroke(Theme.outline.opacity(0.55), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
            ropePath
                .stroke(LinearGradient(colors: [Theme.caramel, Color(hex: "8A5E3C")], startPoint: .top, endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
            ropePath
                .stroke(Color(hex: "EFCC7A", opacity: 0.7), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 9]))
        }
    }

    private var ropePath: Path {
        Path { p in
            guard let first = points.first else { return }
            p.move(to: first)
            for i in 1..<points.count {
                let a = points[i - 1]
                let b = points[i]
                let midX = (a.x + b.x) / 2 + (i.isMultiple(of: 2) ? 40 : -40)
                let midY = (a.y + b.y) / 2
                p.addQuadCurve(to: b, control: CGPoint(x: midX, y: midY))
            }
        }
    }
}

/// Lightweight themed placeholder for the non-map tabs (Stories / Treasures).
struct SectionPanel: View {
    let title: String
    let icon: String
    let blurb: String

    var body: some View {
        ZStack {
            MapBackdrop()
            VStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 62))
                    .foregroundStyle(Theme.brassDeep)
                Text(title)
                    .font(Theme.display(36, weight: .black))
                    .foregroundStyle(Theme.brassDeep)
                Text(blurb)
                    .font(Theme.body(20))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                Text("Coming soon ✦")
                    .font(Theme.hand(27))
                    .foregroundStyle(Theme.terracotta)
            }
            MapBorderOverlay()
        }
    }
}

/// The "Ask" tab — Poli invites a question and opens the full compass on tap.
struct AskPanel: View {
    let openCompass: () -> Void

    var body: some View {
        ZStack {
            MapBackdrop()
            VStack(spacing: 20) {
                Spacer()
                PoliImage(pose: .waving, size: 160)
                Text("Ask Poli")
                    .font(Theme.display(34, weight: .black))
                    .foregroundStyle(Theme.brassDeep)
                Text("Tap Poli to ask about the story.")
                    .font(Theme.body(20))
                    .foregroundStyle(Theme.inkSoft)
                Button(action: openCompass) {
                    Text("✦ Tap to talk")
                        .font(Theme.body(21, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 32).padding(.vertical, 16)
                        .background(Capsule().fill(Theme.sage))
                        .overlay(Capsule().strokeBorder(Theme.outline, lineWidth: 3))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            MapBorderOverlay()
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: openCompass)
    }
}
