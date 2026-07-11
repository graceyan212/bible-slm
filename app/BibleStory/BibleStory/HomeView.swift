import SwiftUI
import BibleStoryCore

enum HomeRoute: Hashable { case story, compass }

/// The child-zone home — "The Expedition" treasure map. A parchment field ringed
/// by an ornate rope border, an illuminated banner, and framed story "stops"
/// strung along a winding rope up to the glowing active lesson, with Poli the
/// compass mascot pointing at START LESSON. A bottom map tab bar switches sections.
struct HomeView: View {
    let env: AppEnvironment
    @State private var path: [HomeRoute] = []
    @State private var tab: MapTab = .map

    init(env: AppEnvironment) {
        self.env = env
        // Dev/screenshot deep-links (see BibleStoryApp `-uiPreviewChild`).
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-uiPreviewTreasures") { _tab = State(initialValue: .treasures) }
        if args.contains("-uiPreviewStory") { _path = State(initialValue: [.story]) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case .map:       expeditionMap
                    case .stories:   SectionPanel(title: "Stories", icon: "book.pages", blurb: "Every story you've explored on the trail.")
                    case .ask:       AskPanel { path.append(.compass) }
                    case .treasures: TreasuresView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                MapTabBar(selection: $tab)
            }
            .background(Theme.parchment.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await env.enterParentZone() }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                    .accessibilityLabel("Parent area")
                    .disabled(env.isAuthenticating)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .story: StoryView(env: env)
                case .compass: CompassView(env: env)
                }
            }
        }
    }

    // MARK: The framed treasure-map screen (the "Map" tab)

    private var expeditionMap: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let stopW = w * 0.45   // frame width (matches expedition-home.html)

            ZStack {
                PaintedMapBackdrop()
                    .frame(width: w, height: h)
                    .clipped()

                ExpeditionBanner(title: "THE EXPEDITION")
                    .frame(width: w * 0.92)
                    .position(x: w * 0.5, y: h * 0.075)

                // Four story stops, staggered down the map (positions from
                // build_map_mockup.py LAYOUT). Only the current story glows; done
                // stops carry a ✓, the not-yet story a lock.
                PaintedStoryFrame(coverAsset: "CoverCreation", title: "Creation", state: .done) {
                    path.append(.story)
                }
                .frame(width: stopW)
                .position(x: w * 0.33, y: h * 0.22)

                PaintedStoryFrame(coverAsset: "CoverRedSea", title: "The Red Sea", state: .done) {
                    path.append(.story)
                }
                .frame(width: stopW)
                .position(x: w * 0.66, y: h * 0.40)

                PaintedStoryFrame(coverAsset: "CoverJesusChildren", title: "Jesus & the Children", state: .active) {
                    path.append(.story)
                }
                .frame(width: stopW)
                .position(x: w * 0.33, y: h * 0.58)

                PaintedStoryFrame(coverAsset: "CoverThePromise", title: "The Promise", state: .locked)
                    .frame(width: stopW)
                    .position(x: w * 0.66, y: h * 0.76)
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .ignoresSafeArea(edges: .top)
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
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 54))
                    .foregroundStyle(Theme.brassDeep)
                Text(title)
                    .font(Theme.display(28, weight: .black))
                    .foregroundStyle(Theme.brassDeep)
                Text(blurb)
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Text("Coming soon ✦")
                    .font(Theme.hand(22))
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
                PoliCompassView(size: 150)
                Text("Ask Poli")
                    .font(Theme.display(26, weight: .black))
                    .foregroundStyle(Theme.brassDeep)
                Text("Tap Poli to ask about the story.")
                    .font(Theme.body(16))
                    .foregroundStyle(Theme.inkSoft)
                Button(action: openCompass) {
                    Text("✦ Tap to talk")
                        .font(Theme.body(17, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 28).padding(.vertical, 14)
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
