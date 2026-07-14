import SwiftUI
import UIKit
import BibleStoryCore

// MARK: - Theme (ported from design/tokens.css — "Treasure Trail" explorer's-journal world)

/// Warm treasure-map palette + fonts. Raw hex sampled from the design board:
/// 60% aged parchment · 30% sand/caramel paper · 10% brass-gold + sage.
/// Fonts fall back to system serif/rounded (design lists Georgia/system fallbacks),
/// so nothing needs to be bundled.
enum Theme {
    // Parchment field
    static let parchment     = Color(hex: 0xF0E1C0)
    static let parchmentLit   = Color(hex: 0xFBF3E1)
    static let parchmentDeep  = Color(hex: 0xE4CFA1)
    static let sand           = Color(hex: 0xD8C08B)
    // Ink
    static let ink            = Color(hex: 0x3B2E23)
    static let inkSoft        = Color(hex: 0x6E5A44)
    static let sepiaLine      = Color(hex: 0xB79A6B)
    static let outline        = Color(hex: 0x3B2E23)
    // Brass / gold (the hero 10%)
    static let brass          = Color(hex: 0xD19A44)
    static let brassLit       = Color(hex: 0xEFCC7A)
    static let brassDeep      = Color(hex: 0x9A6B24)
    // Warm accents
    static let caramel        = Color(hex: 0xB0805A)
    static let terracotta     = Color(hex: 0xC2683C)
    static let rose           = Color(hex: 0xD98E6A)
    // Sage / sea
    static let sage           = Color(hex: 0x8FA79B)
    static let sageDeep       = Color(hex: 0x6E8A80)
    static let sea            = Color(hex: 0xA9C0BA)
    // Utility
    static let cream          = Color(hex: 0xFFF8EA)
    static let warmBrick      = Color(hex: 0xB4472C)
    static let locked         = Color(hex: 0xC3B08A)

    // Fonts — the finished design's real faces (bundled + registered by AppFonts).
    // IM Fell English → headings/banner/titles; IM Fell English SC → small-caps
    // labels; Atkinson Hyperlegible → body/UI; IM Fell English Italic → the "hand".
    // Each degrades to the closest system face if the bundled font fails to load.
    private static let imFellRoman  = "IM_FELL_English_Roman"
    private static let imFellItalic = "IM_FELL_English_Italic"
    private static let imFellSC     = "IM_FELL_English_SC"
    private static let atkinson     = "AtkinsonHyperlegible-Regular"
    private static let atkinsonBold = "AtkinsonHyperlegible-Bold"

    /// True when a face is registered and resolvable by name.
    private static func available(_ name: String) -> Bool { UIFont(name: name, size: 12) != nil }

    private static func isBoldish(_ w: Font.Weight) -> Bool {
        switch w { case .semibold, .bold, .heavy, .black: return true; default: return false }
    }

    /// Global type scale. It's a kids' app (ages 7–9), so everything runs a bit larger
    /// than a typical adult UI — applied uniformly so the visual hierarchy is preserved.
    static let textScale: CGFloat = 1.15

    /// Display serif — IM Fell English (falls back to bold system serif).
    static func display(_ size: CGFloat, weight: Font.Weight = .black) -> Font {
        let s = size * textScale
        return available(imFellRoman) ? .custom(imFellRoman, size: s)
                                      : .system(size: s, weight: weight, design: .serif)
    }
    /// Small-caps map/label serif — IM Fell English SC (falls back to system serif).
    static func mapCaps(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        let s = size * textScale
        return available(imFellSC) ? .custom(imFellSC, size: s)
                                   : .system(size: s, weight: weight, design: .serif)
    }
    /// Body / UI — Atkinson Hyperlegible (Regular or Bold; falls back to rounded system).
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = isBoldish(weight) ? atkinsonBold : atkinson
        let s = size * textScale
        return available(name) ? .custom(name, size: s)
                               : .system(size: s, weight: weight, design: .rounded)
    }
    /// Bottom nav-bar labels. These deliberately OPT OUT of the global `textScale`:
    /// the wood plank is a fixed height and must seat 4 word-labels + the center
    /// mascot without them touching, so nav labels use an explicit compact point size.
    static func navLabel(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name = isBoldish(weight) ? atkinsonBold : atkinson
        return available(name) ? .custom(name, size: size)
                               : .system(size: size, weight: weight, design: .rounded)
    }

    /// Poli's warm "voice" (speech bubbles, verse text, asides). This USED to be the
    /// decorative IM Fell English Italic script, but that italic is hard for 7–9-year-olds
    /// to read — so it now uses the same highly legible Atkinson Hyperlegible as body copy
    /// (a touch bolder for warmth). Readability wins in a kids' app.
    static func hand(_ size: CGFloat) -> Font {
        let s = size * textScale
        return available(atkinson) ? .custom(atkinson, size: s)
                                   : .system(size: s, weight: .medium, design: .rounded)
    }
}

extension Color {
    /// 0xRRGGBB literal → Color (sRGB).
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue:  Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }

    /// "RRGGBB" or "#RRGGBB" string → Color (sRGB).
    init(hex string: String, opacity: Double = 1) {
        let cleaned = string.hasPrefix("#") ? String(string.dropFirst()) : string
        let value = UInt32(cleaned, radix: 16) ?? 0
        self.init(hex: value, opacity: opacity)
    }
}

/// Poli's illustrated poses (the `final_compass_mascot_set` art, bundled as assets).
/// One pose per emotional beat, reused across onboarding, the trail, and the Ask page.
enum PoliPose: String {
    case waving      = "PoliWaving"
    case pointing    = "PoliPointing"
    case praying     = "PoliPraying"
    case celebrating = "PoliCelebrating"
    case thumbsUp    = "PoliThumbsUp"
}

/// The mascot, rendered from the illustrated pose art. Session-agnostic, so it can
/// be dropped anywhere (onboarding, HUD, reward moments) — not just the ask loop.
/// Falls back to the compass emoji if the asset is ever missing.
struct PoliImage: View {
    let pose: PoliPose
    var size: CGFloat = 120

    var body: some View {
        Group {
            if UIImage(named: pose.rawValue) != nil {
                Image(pose.rawValue).resizable().scaledToFit()
            } else {
                Text("🧭").font(.system(size: size * 0.5))
            }
        }
        .frame(width: size, height: size)
    }
}

/// Poli, the trail-compass mascot — state-driven (idle/listening/thinking/answering).
/// Maps each ask-loop state to an illustrated pose, with a soft state glow + caption.
struct PoliMascotView: View {
    let state: AskSessionModel.PoliState
    var size: CGFloat = 116

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(glow.opacity(0.28)).frame(width: size * 0.86, height: size * 0.86).blur(radius: 6)
                PoliImage(pose: pose, size: size)
            }
            Text(caption).font(Theme.body(15)).foregroundStyle(.secondary)
        }
        .accessibilityLabel("Poli, \(caption)")
    }

    private var pose: PoliPose {
        switch state {
        case .idle: .waving
        case .listening: .pointing
        case .thinking: .praying
        case .answering: .thumbsUp
        }
    }
    private var glow: Color {
        switch state {
        case .idle: .orange
        case .listening: .teal
        case .thinking: .purple
        case .answering: .yellow
        }
    }
    private var caption: String {
        switch state {
        case .idle: "tap to talk"
        case .listening: "listening…"
        case .thinking: "thinking…"
        case .answering: "Poli says…"
        }
    }
}

/// The persistent "ask your guide" button (Home dock). Tapping opens the Compass.
struct PoliFAB: View {
    var state: AskSessionModel.PoliState = .idle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("✦ tap Poli if you have a question")
                    .font(Theme.body(14)).foregroundStyle(.secondary)
                PoliMascotView(state: state)
            }
        }
        .buttonStyle(.plain)
        .padding(.bottom, 8)
    }
}

/// The ONE standard page header for every top-level screen (Map, Story Library,
/// Treasures, Family Dashboard) so titles share the same position, font, and size.
/// Place it pinned at the top of each screen's content.
struct ScreenTitle: View {
    let text: String
    var subtitle: String? = nil
    /// Positional init so callers read naturally: `ScreenTitle("Story Library", subtitle: …)`.
    init(_ text: String, subtitle: String? = nil) {
        self.text = text
        self.subtitle = subtitle
    }
    var body: some View {
        VStack(spacing: 2) {
            Text(text)
                .font(Theme.display(30, weight: .black))
                .foregroundStyle(Theme.brassDeep)
                .shadow(color: Theme.cream.opacity(0.6), radius: 0.5, x: 0, y: -1)
                .lineLimit(1).minimumScaleFactor(0.6)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .padding(.horizontal, 20)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A stop on the treasure-map trail. State = color + icon + size (colorblind-safe).
struct TrailNodeView: View {
    enum NodeState { case locked, active, done, milestone }
    let state: NodeState
    let label: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button { action?() } label: {
            HStack(spacing: 12) {
                Text(icon).font(.title2)
                Text(label).font(.headline)
                if state == .active {
                    Spacer()
                    Text("START").font(.caption).bold()
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.yellow, in: Capsule())
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(bg, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(state != .active)
        .accessibilityHint(state == .active ? "Start this story" : "")
    }

    private var icon: String {
        switch state {
        case .locked: "🔒"
        case .active: "✦"
        case .done: "✓"
        case .milestone: "💎"
        }
    }
    private var bg: Color {
        switch state {
        case .locked: .gray.opacity(0.12)
        case .active: .orange.opacity(0.28)
        case .done: .green.opacity(0.15)
        case .milestone: .brown.opacity(0.18)
        }
    }
}

/// Polymorphic reply surface — the tier decides which card renders (behavior-spec v2).
struct ReplySurfaceView: View {
    let response: QuestionResponse

    var body: some View {
        switch response.behaviorClass {
        case .deflect:
            card(icon: "house.fill", tint: .brown) {
                Text(response.spokenText).font(Theme.body(19))
            }
        case .danger:
            card(icon: "heart.fill", tint: .red) {
                Text(response.spokenText).font(Theme.body(19))
            }
        default:
            card(icon: "sparkles", tint: .orange) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("✦ Poli says").font(Theme.body(14, weight: .bold))
                    Text(response.spokenText).font(Theme.body(19))
                    if response.retrievedVerse != nil || !response.claimIDs.isEmpty {
                        Label("Read it in your Bible with a grown-up", systemImage: "book")
                            .font(Theme.body(14)).foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func card(icon: String, tint: Color, @ViewBuilder _ content: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }
}

// =============================================================================
// MARK: - Treasure-Map Screen ("The Expedition") — vector-art skin
// The pieces below reproduce the illustrated treasure-map home: parchment field,
// ornate rope border, illuminated banner, framed story "stops", the Poli compass
// mascot, and the bottom map tab bar. All pure SwiftUI (no image/font assets).
// =============================================================================

// MARK: Poli — the friendly brass pocket-compass mascot (vector port of design/mascot.svg)

struct PoliCompassView: View {
    var size: CGFloat = 120

    @State private var bob = false      // needle cowlick bob
    @State private var breathe = false  // gentle idle breathing

    private let ink = Color(hex: "140F38")
    private let brassMid = Color(hex: "FFC24B")
    private let brassHi = Color(hex: "FFD25E")
    private let engrave = Color(hex: "8A5A16")

    private var brassBody: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "FFE7A8"), location: 0.0),
                .init(color: Color(hex: "FFC24B"), location: 0.45),
                .init(color: Color(hex: "D98A2B"), location: 1.0)
            ],
            startPoint: .top, endPoint: .bottom)
    }
    private var rimGold: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FFE49A"), Color(hex: "E9A23B")],
            startPoint: .top, endPoint: .bottom)
    }
    private var glass: RadialGradient {
        RadialGradient(
            stops: [
                .init(color: Color(hex: "DCE7EC"), location: 0.0),
                .init(color: Color(hex: "AFC4CE"), location: 0.55),
                .init(color: Color(hex: "8AA3B2"), location: 1.0)
            ],
            center: UnitPoint(x: 0.42, y: 0.34),
            startRadius: 0, endRadius: 104)
    }
    private var ember: RadialGradient {
        RadialGradient(
            stops: [
                .init(color: Color(hex: "FFD3A6", opacity: 0.95), location: 0.0),
                .init(color: Color(hex: "FF9E5A", opacity: 0.45), location: 0.55),
                .init(color: Color(hex: "FF9E5A", opacity: 0.0), location: 1.0)
            ],
            center: .center, startRadius: 0, endRadius: 58)
    }
    private var needleGold: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "FFF6DE"), location: 0.0),
                .init(color: Color(hex: "FFD25E"), location: 0.55),
                .init(color: Color(hex: "F2B01F"), location: 1.0)
            ],
            startPoint: UnitPoint(x: 0.5, y: 78.0 / 300.0),
            endPoint: UnitPoint(x: 0.5, y: 140.0 / 300.0))
    }
    private var needleGlow: RadialGradient {
        RadialGradient(
            colors: [Color(hex: "FFE9A6", opacity: 0.85), Color(hex: "FFE9A6", opacity: 0.0)],
            center: .center, startRadius: 0, endRadius: 30)
    }
    private var aura: RadialGradient {
        RadialGradient(
            stops: [
                .init(color: Color(hex: "FFB877", opacity: 0.55), location: 0.0),
                .init(color: Color(hex: "FF9E5A", opacity: 0.12), location: 0.60),
                .init(color: Color(hex: "FF9E5A", opacity: 0.0), location: 1.0)
            ],
            center: UnitPoint(x: 0.5, y: 0.52),
            startRadius: 0, endRadius: 150)
    }

    var body: some View {
        content
            .frame(width: 260, height: 300)
            .scaleEffect(breathe ? 1.015 : 1.0, anchor: .bottom)
            .scaleEffect(size / 260.0)
            .frame(width: size, height: size * 300.0 / 260.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) { bob = true }
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) { breathe = true }
            }
    }

    private var content: some View {
        ZStack {
            Ellipse().fill(aura).frame(width: 256, height: 280).position(x: 130, y: 158)

            // arms + hands
            PoliAbsPath { p in
                p.move(to: CGPoint(x: 64, y: 176))
                p.addQuadCurve(to: CGPoint(x: 36, y: 196), control: CGPoint(x: 46, y: 190))
            }.stroke(ink, style: StrokeStyle(lineWidth: 17, lineCap: .round, lineJoin: .round)).frame(width: 260, height: 300)
            PoliAbsPath { p in
                p.move(to: CGPoint(x: 64, y: 176))
                p.addQuadCurve(to: CGPoint(x: 36, y: 196), control: CGPoint(x: 46, y: 190))
            }.stroke(brassMid, style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round)).frame(width: 260, height: 300)
            circle(fill: brassMid, r: 15, x: 34, y: 198)

            PoliAbsPath { p in
                p.move(to: CGPoint(x: 196, y: 150))
                p.addQuadCurve(to: CGPoint(x: 230, y: 100), control: CGPoint(x: 220, y: 122))
            }.stroke(ink, style: StrokeStyle(lineWidth: 17, lineCap: .round, lineJoin: .round)).frame(width: 260, height: 300)
            PoliAbsPath { p in
                p.move(to: CGPoint(x: 196, y: 150))
                p.addQuadCurve(to: CGPoint(x: 230, y: 100), control: CGPoint(x: 220, y: 122))
            }.stroke(brassMid, style: StrokeStyle(lineWidth: 11, lineCap: .round, lineJoin: .round)).frame(width: 260, height: 300)
            circle(fill: brassHi, r: 15, x: 231, y: 96)

            // hanging loop
            Circle().stroke(ink, lineWidth: 13).frame(width: 38, height: 38).position(x: 130, y: 50)
            Circle().stroke(rimGold, lineWidth: 7).frame(width: 38, height: 38).position(x: 130, y: 50)

            // compass case
            Circle().fill(brassBody).overlay(Circle().strokeBorder(ink, lineWidth: 6))
                .frame(width: 184, height: 184).position(x: 130, y: 160)
            Circle().stroke(rimGold, lineWidth: 12).frame(width: 164, height: 164).position(x: 130, y: 160)

            // N/E/W/S
            newsLetter("N", x: 130, y: 82)
            newsLetter("E", x: 205, y: 160)
            newsLetter("W", x: 55, y: 160)
            newsLetter("S", x: 130, y: 238)

            // glass dome
            Circle().fill(glass).overlay(Circle().strokeBorder(ink, lineWidth: 5))
                .frame(width: 142, height: 142).position(x: 130, y: 160)
            Ellipse().fill(ember).frame(width: 116, height: 84).position(x: 130, y: 196)
            PoliAbsPath { p in
                p.move(to: CGPoint(x: 78, y: 128))
                p.addQuadCurve(to: CGPoint(x: 134, y: 96), control: CGPoint(x: 96, y: 96))
            }.stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 7, lineCap: .round)).frame(width: 260, height: 300)

            // needle
            Circle().fill(needleGlow).frame(width: 60, height: 60).position(x: 130, y: 112)
            needleGroup.frame(width: 260, height: 300)
                .rotationEffect(.degrees(bob ? 4 : -4), anchor: UnitPoint(x: 130.0 / 260.0, y: 140.0 / 300.0))

            // eyes
            eye(x: 108, y: 160); eye(x: 152, y: 160)
            circle(fill: Color(hex: "33291F"), r: 7.5, x: 111, y: 163)
            circle(fill: Color(hex: "33291F"), r: 7.5, x: 155, y: 163)
            circle(fill: .white, r: 2.6, x: 114, y: 159)
            circle(fill: .white, r: 2.6, x: 158, y: 159)

            // cheeks
            Ellipse().fill(Color(hex: "E28A6A", opacity: 0.6)).frame(width: 22, height: 14).position(x: 90, y: 182)
            Ellipse().fill(Color(hex: "E28A6A", opacity: 0.6)).frame(width: 22, height: 14).position(x: 170, y: 182)

            // smile
            PoliAbsPath { p in
                p.move(to: CGPoint(x: 113, y: 186))
                p.addQuadCurve(to: CGPoint(x: 147, y: 186), control: CGPoint(x: 130, y: 200))
            }.stroke(Color(hex: "33291F"), style: StrokeStyle(lineWidth: 4.5, lineCap: .round)).frame(width: 260, height: 300)

            // feet
            foot(x: 106, y: 250); foot(x: 154, y: 250)

            // sparkles
            star(cx: 40, cy: 98, fill: Color(hex: "FFF3D6"))
            star(cx: 210, cy: 61, fill: Color(hex: "D98E6A"), scale: 0.8)
            star(cx: 224, cy: 223, fill: Color(hex: "8FA79B"), scale: 0.8)
            circle(fill: Color(hex: "B0805A"), r: 3, x: 60, y: 250)
            circle(fill: Color(hex: "D19A44"), r: 2.4, x: 196, y: 238)
        }
    }

    private var needlePoly: PoliAbsPath {
        PoliAbsPath { p in
            let pts: [CGPoint] = [
                .init(x: 130, y: 80), .init(x: 137, y: 105), .init(x: 148, y: 112),
                .init(x: 137, y: 119), .init(x: 130, y: 140), .init(x: 123, y: 119),
                .init(x: 112, y: 112), .init(x: 123, y: 105)
            ]
            p.move(to: pts[0])
            for pt in pts.dropFirst() { p.addLine(to: pt) }
            p.closeSubpath()
        }
    }
    private var needleGroup: some View {
        ZStack {
            needlePoly.fill(needleGold)
            needlePoly.stroke(ink, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            Circle().fill(.white).frame(width: 8, height: 8).position(x: 130, y: 88)
        }
    }
    private func eye(x: CGFloat, y: CGFloat) -> some View {
        Ellipse().fill(Color.white).overlay(Ellipse().strokeBorder(ink, lineWidth: 3))
            .frame(width: 30, height: 36).position(x: x, y: y)
    }
    private func foot(x: CGFloat, y: CGFloat) -> some View {
        Ellipse().fill(brassMid).overlay(Ellipse().strokeBorder(ink, lineWidth: 4))
            .frame(width: 32, height: 20).position(x: x, y: y)
    }
    private func circle(fill: Color, r: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        Circle().fill(fill).frame(width: r * 2, height: r * 2).position(x: x, y: y)
    }
    private func newsLetter(_ s: String, x: CGFloat, y: CGFloat) -> some View {
        Text(s).font(.system(size: 15, weight: .semibold, design: .serif))
            .foregroundStyle(engrave.opacity(0.6)).position(x: x, y: y)
    }
    private func star(cx: CGFloat, cy: CGFloat, fill: Color, scale: CGFloat = 1) -> some View {
        PoliAbsPath { p in
            let a: CGFloat = 12 * scale
            let b: CGFloat = 4 * scale
            let pts: [CGPoint] = [
                .init(x: cx, y: cy - a), .init(x: cx + b, y: cy - b),
                .init(x: cx + a, y: cy), .init(x: cx + b, y: cy + b),
                .init(x: cx, y: cy + a), .init(x: cx - b, y: cy + b),
                .init(x: cx - a, y: cy), .init(x: cx - b, y: cy - b)
            ]
            p.move(to: pts[0])
            for pt in pts.dropFirst() { p.addLine(to: pt) }
            p.closeSubpath()
        }.fill(fill).frame(width: 260, height: 300)
    }
}

/// Draws in absolute 260×300 coordinates (ignores rect) so SVG coords port verbatim.
private struct PoliAbsPath: Shape {
    let build: @Sendable (inout Path) -> Void
    init(_ build: @escaping @Sendable (inout Path) -> Void) { self.build = build }
    func path(in rect: CGRect) -> Path { var p = Path(); build(&p); return p }
}

// MARK: Map backdrop, compass rose, and ornate border

struct MapBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Theme.parchment
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "FCF5E6", opacity: 1.0), location: 0.0),
                        .init(color: Color(hex: "FCF5E6", opacity: 0.0), location: 0.52)
                    ]),
                    center: UnitPoint(x: 0.5, y: -0.08), startRadius: 0, endRadius: max(w, h) * 0.95)
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "D19A44", opacity: 0.14), location: 0.0),
                        .init(color: Color(hex: "D19A44", opacity: 0.0), location: 0.60)
                    ]),
                    center: UnitPoint(x: 0.5, y: 1.20), startRadius: 0, endRadius: max(w, h) * 0.90)
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "78542A", opacity: 0.0), location: 0.62),
                        .init(color: Color(hex: "78542A", opacity: 0.14), location: 1.0)
                    ]),
                    center: .center, startRadius: 0, endRadius: max(w, h) * 0.75)

                MapEngravings.seaSerpent.stroke(Theme.sepiaLine, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 120, height: 46).opacity(0.14).rotationEffect(.degrees(-8)).position(x: w * 0.24, y: h * 0.20)
                MapEngravings.seaSerpent.stroke(Theme.sepiaLine, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 100, height: 40).opacity(0.12).rotationEffect(.degrees(166)).position(x: w * 0.78, y: h * 0.72)
                MapEngravings.scroll.stroke(Theme.sepiaLine, style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
                    .frame(width: 58, height: 42).opacity(0.15).rotationEffect(.degrees(-12)).position(x: w * 0.82, y: h * 0.28)
                MapEngravings.scroll.stroke(Theme.sepiaLine, style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
                    .frame(width: 48, height: 36).opacity(0.12).rotationEffect(.degrees(9)).position(x: w * 0.18, y: h * 0.62)
                MapEngravings.gem.stroke(Theme.sepiaLine, style: StrokeStyle(lineWidth: 1.3, lineJoin: .round))
                    .frame(width: 26, height: 26).opacity(0.16).position(x: w * 0.66, y: h * 0.16)
                MapEngravings.gem.stroke(Theme.sepiaLine, style: StrokeStyle(lineWidth: 1.2, lineJoin: .round))
                    .frame(width: 20, height: 20).opacity(0.13).position(x: w * 0.30, y: h * 0.84)
                MapEngravings.gem.stroke(Theme.sepiaLine, style: StrokeStyle(lineWidth: 1.1, lineJoin: .round))
                    .frame(width: 16, height: 16).opacity(0.11).position(x: w * 0.50, y: h * 0.40)
                MapEngravings.chest.stroke(Theme.sepiaLine, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 64, height: 52).opacity(0.15).position(x: w * 0.72, y: h * 0.88)
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
    }
}

struct CompassRose: View {
    var color: Color = Theme.sepiaLine
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let p: (CGFloat, CGFloat) -> CGPoint = { x, y in CGPoint(x: x / 100 * s, y: y / 100 * s) }
            ZStack {
                Circle().stroke(color, lineWidth: 1.2 / 100 * s).frame(width: 74 / 100 * s, height: 74 / 100 * s)
                Circle().stroke(color, lineWidth: 1.2 / 100 * s).frame(width: 60 / 100 * s, height: 60 / 100 * s)
                Path { path in
                    path.addLines([p(50, 5), p(56, 47), p(50, 52), p(44, 47)]); path.closeSubpath()
                    path.addLines([p(95, 50), p(53, 56), p(48, 50), p(53, 44)]); path.closeSubpath()
                    path.addLines([p(50, 95), p(44, 53), p(50, 48), p(56, 53)]); path.closeSubpath()
                    path.addLines([p(5, 50), p(47, 44), p(52, 50), p(47, 56)]); path.closeSubpath()
                }.fill(color)
                Circle().fill(color).frame(width: 6.8 / 100 * s, height: 6.8 / 100 * s)
                Path { path in
                    path.addLines([p(72, 28), p(53, 47), p(50, 50), p(51, 45)]); path.closeSubpath()
                    path.addLines([p(72, 72), p(51, 55), p(50, 50), p(55, 51)]); path.closeSubpath()
                    path.addLines([p(28, 72), p(47, 53), p(50, 50), p(49, 55)]); path.closeSubpath()
                    path.addLines([p(28, 28), p(49, 45), p(50, 50), p(45, 49)]); path.closeSubpath()
                }.fill(color).opacity(0.55)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

struct MapBorderOverlay: View {
    private let inset: CGFloat = 10
    private let band: CGFloat = 19
    private let corner: CGFloat = 34
    var body: some View {
        GeometryReader { geo in
            let outerRadius: CGFloat = 40
            let framedRect = CGRect(x: inset, y: inset, width: geo.size.width - inset * 2, height: geo.size.height - inset * 2)
            ZStack {
                RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [Theme.caramel, Color(hex: "8A5E3C"), Theme.caramel], startPoint: .top, endPoint: .bottom),
                        lineWidth: band)
                    .padding(inset)
                RoundedRectangle(cornerRadius: outerRadius, style: .continuous)
                    .strokeBorder(Theme.outline, lineWidth: 2).padding(inset)
                RoundedRectangle(cornerRadius: outerRadius - band, style: .continuous)
                    .strokeBorder(Theme.outline, lineWidth: 2).padding(inset + band)
                RoundedRectangle(cornerRadius: outerRadius - band / 2, style: .continuous)
                    .strokeBorder(Color(hex: "EFCC7A", opacity: 0.55), style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    .padding(inset + band / 2)
                CompassRose(color: Theme.sepiaLine).frame(width: corner, height: corner).opacity(0.20)
                    .position(x: framedRect.minX + band + corner / 2 + 4, y: framedRect.minY + band + corner / 2 + 4)
                CompassRose(color: Theme.sepiaLine).frame(width: corner, height: corner).opacity(0.20)
                    .position(x: framedRect.maxX - band - corner / 2 - 4, y: framedRect.minY + band + corner / 2 + 4)
                CompassRose(color: Theme.sepiaLine).frame(width: corner, height: corner).opacity(0.20)
                    .position(x: framedRect.minX + band + corner / 2 + 4, y: framedRect.maxY - band - corner / 2 - 4)
                CompassRose(color: Theme.sepiaLine).frame(width: corner, height: corner).opacity(0.20)
                    .position(x: framedRect.maxX - band - corner / 2 - 4, y: framedRect.maxY - band - corner / 2 - 4)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private enum MapEngravings {
    static var seaSerpent: some Shape { MapNormShape { rect in
        Path { p in
            let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
            p.move(to: CGPoint(x: x, y: y + h * 0.7))
            p.addCurve(to: CGPoint(x: x + w * 0.28, y: y + h * 0.25), control1: CGPoint(x: x + w * 0.08, y: y + h * 0.35), control2: CGPoint(x: x + w * 0.20, y: y + h * 0.25))
            p.addCurve(to: CGPoint(x: x + w * 0.55, y: y + h * 0.7), control1: CGPoint(x: x + w * 0.38, y: y + h * 0.25), control2: CGPoint(x: x + w * 0.47, y: y + h * 0.7))
            p.addCurve(to: CGPoint(x: x + w * 0.80, y: y + h * 0.25), control1: CGPoint(x: x + w * 0.65, y: y + h * 0.7), control2: CGPoint(x: x + w * 0.72, y: y + h * 0.25))
            p.addCurve(to: CGPoint(x: x + w, y: y + h * 0.45), control1: CGPoint(x: x + w * 0.90, y: y + h * 0.25), control2: CGPoint(x: x + w * 0.96, y: y + h * 0.35))
            p.move(to: CGPoint(x: x + w, y: y + h * 0.45))
            p.addLine(to: CGPoint(x: x + w * 0.90, y: y + h * 0.52))
        }
    } }
    static var scroll: some Shape { MapNormShape { rect in
        Path { p in
            let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
            let curl = w * 0.16
            p.addEllipse(in: CGRect(x: x, y: y, width: curl * 2, height: h * 0.28))
            p.addEllipse(in: CGRect(x: x + w - curl * 2, y: y + h * 0.72, width: curl * 2, height: h * 0.28))
            p.move(to: CGPoint(x: x + curl, y: y + h * 0.14)); p.addLine(to: CGPoint(x: x + w - curl, y: y + h * 0.14))
            p.move(to: CGPoint(x: x + curl, y: y + h * 0.86)); p.addLine(to: CGPoint(x: x + w - curl, y: y + h * 0.86))
            p.move(to: CGPoint(x: x + curl, y: y + h * 0.14)); p.addLine(to: CGPoint(x: x + curl, y: y + h * 0.86))
            p.move(to: CGPoint(x: x + w - curl, y: y + h * 0.14)); p.addLine(to: CGPoint(x: x + w - curl, y: y + h * 0.86))
            p.move(to: CGPoint(x: x + curl * 1.6, y: y + h * 0.38)); p.addLine(to: CGPoint(x: x + w - curl * 1.6, y: y + h * 0.38))
            p.move(to: CGPoint(x: x + curl * 1.6, y: y + h * 0.56)); p.addLine(to: CGPoint(x: x + w - curl * 1.6, y: y + h * 0.56))
        }
    } }
    static var gem: some Shape { MapNormShape { rect in
        Path { p in
            let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
            let girdle = y + h * 0.36
            p.move(to: CGPoint(x: x + w * 0.28, y: y)); p.addLine(to: CGPoint(x: x + w * 0.72, y: y))
            p.addLine(to: CGPoint(x: x + w, y: girdle)); p.addLine(to: CGPoint(x: x + w * 0.5, y: y + h))
            p.addLine(to: CGPoint(x: x, y: girdle)); p.closeSubpath()
            p.move(to: CGPoint(x: x, y: girdle)); p.addLine(to: CGPoint(x: x + w, y: girdle))
            p.move(to: CGPoint(x: x + w * 0.28, y: y)); p.addLine(to: CGPoint(x: x + w * 0.38, y: girdle)); p.addLine(to: CGPoint(x: x + w * 0.5, y: y + h))
            p.move(to: CGPoint(x: x + w * 0.72, y: y)); p.addLine(to: CGPoint(x: x + w * 0.62, y: girdle)); p.addLine(to: CGPoint(x: x + w * 0.5, y: y + h))
        }
    } }
    static var chest: some Shape { MapNormShape { rect in
        Path { p in
            let x = rect.minX, y = rect.minY, w = rect.width, h = rect.height
            let lidH = h * 0.38
            p.addRect(CGRect(x: x, y: y + lidH, width: w, height: h - lidH))
            p.move(to: CGPoint(x: x, y: y + lidH))
            p.addCurve(to: CGPoint(x: x + w, y: y + lidH), control1: CGPoint(x: x + w * 0.1, y: y), control2: CGPoint(x: x + w * 0.9, y: y))
            p.move(to: CGPoint(x: x, y: y + lidH)); p.addLine(to: CGPoint(x: x + w, y: y + lidH))
            p.addRect(CGRect(x: x + w * 0.42, y: y + lidH - h * 0.06, width: w * 0.16, height: h * 0.22))
            p.move(to: CGPoint(x: x + w * 0.22, y: y + lidH * 0.5)); p.addLine(to: CGPoint(x: x + w * 0.22, y: y + h))
            p.move(to: CGPoint(x: x + w * 0.78, y: y + lidH * 0.5)); p.addLine(to: CGPoint(x: x + w * 0.78, y: y + h))
        }
    } }
}

private struct MapNormShape: Shape {
    let build: @Sendable (CGRect) -> Path
    init(_ build: @escaping @Sendable (CGRect) -> Path) { self.build = build }
    func path(in rect: CGRect) -> Path { build(rect) }
}

// MARK: The illuminated "THE EXPEDITION" banner

struct ExpeditionBanner: View {
    var title: String = "THE EXPEDITION"

    private var parts: (dropCap: String, restOfWord: String, tail: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.first != nil else { return ("", "", "") }
        let words = trimmed.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        guard let firstWord = words.first else { return (String(trimmed.first!).uppercased(), "", "") }
        let dropCap = String(firstWord.prefix(1)).uppercased()
        let restOfWord = String(firstWord.dropFirst()).uppercased()
        let tail = words.dropFirst().joined(separator: " ").uppercased()
        return (dropCap, restOfWord, tail)
    }

    var body: some View {
        let p = parts
        ZStack {
            BannerArc().stroke(Theme.brass.opacity(0.35), lineWidth: 2).frame(height: 42).offset(y: 34).blur(radius: 0.3)
            ZStack {
                ScrollBannerShape()
                    .fill(LinearGradient(colors: [Theme.parchmentLit, Theme.parchment, Theme.parchmentDeep], startPoint: .top, endPoint: .bottom))
                    .overlay(ScrollBannerShape().fill(LinearGradient(colors: [Theme.cream.opacity(0.55), .clear], startPoint: .top, endPoint: .center)))
                    .shadow(color: Theme.ink.opacity(0.28), radius: 8, x: 0, y: 5)
                ScrollBannerShape().stroke(Theme.sepiaLine, lineWidth: 2.5)
                ScrollBannerShape().stroke(Theme.brass.opacity(0.6), lineWidth: 1).padding(5)
            }
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                DropCap(letter: p.dropCap).alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 8 }
                Text(p.restOfWord + (p.tail.isEmpty ? "" : " " + p.tail))
                    .font(Theme.mapCaps(32, weight: .heavy))
                    .foregroundStyle(Theme.brassDeep)
                    .tracking(2)
                    .shadow(color: Theme.cream.opacity(0.7), radius: 0.5, x: 0, y: -1)
                    .shadow(color: Theme.ink.opacity(0.45), radius: 1, x: 0, y: 1.5)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            .padding(.horizontal, 46)
        }
        .frame(height: 96)
        .padding(.horizontal, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
    }
}

private struct DropCap: View {
    let letter: String
    var body: some View {
        let size: CGFloat = 48
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: [Theme.brassLit, Theme.brass, Theme.brassDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Theme.outline, lineWidth: 2))
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Theme.cream.opacity(0.5), lineWidth: 1).padding(3))
                .shadow(color: Theme.ink.opacity(0.35), radius: 3, x: 0, y: 2)
            Text(letter).font(Theme.display(34, weight: .black)).foregroundStyle(Theme.cream)
                .shadow(color: Theme.brassDeep.opacity(0.8), radius: 0.5, x: 0, y: 1)
        }
        .frame(width: size, height: size)
    }
}

private struct ScrollBannerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let notch = min(rect.height * 0.42, 26)
        let curl = rect.height * 0.18
        let r = rect.height * 0.32
        let midY = rect.midY
        let leftInner = rect.minX + notch
        let rightInner = rect.maxX - notch
        p.move(to: CGPoint(x: leftInner + r, y: rect.minY + curl))
        p.addLine(to: CGPoint(x: rightInner - r, y: rect.minY + curl))
        p.addQuadCurve(to: CGPoint(x: rightInner, y: rect.minY + curl + r), control: CGPoint(x: rightInner, y: rect.minY + curl))
        p.addLine(to: CGPoint(x: rightInner, y: midY - notch * 0.35))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + curl * 0.6))
        p.addLine(to: CGPoint(x: rightInner + notch * 0.55, y: midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - curl * 0.6))
        p.addLine(to: CGPoint(x: rightInner, y: midY + notch * 0.35))
        p.addLine(to: CGPoint(x: rightInner, y: rect.maxY - curl - r))
        p.addQuadCurve(to: CGPoint(x: rightInner - r, y: rect.maxY - curl), control: CGPoint(x: rightInner, y: rect.maxY - curl))
        p.addLine(to: CGPoint(x: leftInner + r, y: rect.maxY - curl))
        p.addQuadCurve(to: CGPoint(x: leftInner, y: rect.maxY - curl - r), control: CGPoint(x: leftInner, y: rect.maxY - curl))
        p.addLine(to: CGPoint(x: leftInner, y: midY + notch * 0.35))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - curl * 0.6))
        p.addLine(to: CGPoint(x: leftInner - notch * 0.55, y: midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + curl * 0.6))
        p.addLine(to: CGPoint(x: leftInner, y: midY - notch * 0.35))
        p.addLine(to: CGPoint(x: leftInner, y: rect.minY + curl + r))
        p.addQuadCurve(to: CGPoint(x: leftInner + r, y: rect.minY + curl), control: CGPoint(x: leftInner, y: rect.minY + curl))
        p.closeSubpath()
        return p
    }
}

private struct BannerArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.minY))
        return p
    }
}

// MARK: Framed story "stop" card

enum StoryCardState { case active, done, locked }

struct StoryScene {
    let sky: [Color]
    let ground: [Color]
    let glyphs: [String]
    static let garden = StoryScene(sky: [Theme.sea.opacity(0.55), Theme.cream], ground: [Theme.sage, Theme.sage.opacity(0.7)], glyphs: ["🌳", "🌸", "🍃"])
    static let redSea = StoryScene(sky: [Theme.sea, Theme.sea.opacity(0.5)], ground: [Theme.sea.opacity(0.9), Color(hex: "1E5A7A")], glyphs: ["🌊", "🌊"])
    static let jesus = StoryScene(sky: [Theme.caramel.opacity(0.6), Theme.cream], ground: [Theme.sand, Theme.caramel.opacity(0.55)], glyphs: ["✝️", "🧑‍🤝‍🧑"])
}

struct FramedStoryCard: View {
    var title: String
    var scene: StoryScene
    var state: StoryCardState = .active
    var showGem: Bool = true
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) { cardBody }.buttonStyle(.plain)
        } else {
            cardBody
        }
    }

    private var cardBody: some View {
        VStack(spacing: -14) {
            framedPicture.zIndex(0)
            titlePlaque.zIndex(1)
        }
        .saturation(state == .locked ? 0.4 : 1)
        .opacity(state == .locked ? 0.7 : 1)
        .animation(.easeInOut(duration: 0.25), value: state)
    }

    private var framedPicture: some View {
        picture
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(innerBevel)
            .padding(frameBandWidth)
            .background(frameBand)
            .overlay(badge, alignment: .topTrailing)
            .overlay(gem, alignment: .bottomLeading)
            .shadow(color: state == .active ? Theme.brass.opacity(0.6) : Color.black.opacity(0.25),
                    radius: state == .active ? 18 : 8, x: 0, y: state == .active ? 0 : 5)
    }
    private var frameBandWidth: CGFloat { 12 }

    private var frameBand: some View {
        let brassTop = state == .active ? Theme.brassLit : Theme.brass
        return RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(LinearGradient(colors: [brassTop, Theme.brass, Theme.brassDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Theme.outline, lineWidth: 1.5))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).inset(by: 3).strokeBorder(Theme.brassLit.opacity(state == .active ? 0.9 : 0.6), lineWidth: 1))
            .overlay(cornerScrews)
            .brightness(state == .done ? -0.04 : 0)
    }
    private var innerBevel: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(Theme.outline.opacity(0.8), lineWidth: 1.5)
            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).inset(by: 1.5).strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
    }
    private var cornerScrews: some View {
        let inset: CGFloat = 6
        return ZStack {
            screw.position(x: inset, y: inset)
            GeometryReader { geo in
                screw.position(x: geo.size.width - inset, y: inset)
                screw.position(x: inset, y: geo.size.height - inset)
                screw.position(x: geo.size.width - inset, y: geo.size.height - inset)
            }
        }.allowsHitTesting(false)
    }
    private var screw: some View {
        Circle().fill(Theme.brassDeep).frame(width: 5, height: 5)
            .overlay(Circle().stroke(Theme.brassLit.opacity(0.7), lineWidth: 0.5))
    }
    private var picture: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                LinearGradient(colors: scene.sky, startPoint: .top, endPoint: .bottom)
                VStack(spacing: 0) {
                    Color.clear.frame(height: h * 0.58)
                    LinearGradient(colors: scene.ground, startPoint: .top, endPoint: .bottom).clipShape(GroundShape())
                }
                glyphLayer(width: w, height: h)
            }
        }
    }
    private func glyphLayer(width w: CGFloat, height h: CGFloat) -> some View {
        ZStack {
            ForEach(Array(scene.glyphs.enumerated()), id: \.offset) { index, glyph in
                let count = max(scene.glyphs.count, 1)
                let fraction = (CGFloat(index) + 0.5) / CGFloat(count)
                let yJitter = index % 2 == 0 ? h * 0.52 : h * 0.62
                Text(glyph).font(.system(size: min(w, h) * 0.22))
                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                    .position(x: w * fraction, y: yJitter)
            }
        }
    }
    private var titlePlaque: some View {
        Text(title)
            .font(Theme.display(15, weight: .semibold))
            .foregroundStyle(Theme.ink)
            .lineLimit(1).minimumScaleFactor(0.7)
            .padding(.horizontal, 18).padding(.vertical, 7)
            .background(Capsule(style: .continuous).fill(Theme.parchmentLit).shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2))
            .overlay(Capsule(style: .continuous).strokeBorder(Theme.sepiaLine, lineWidth: 1.5))
            .overlay(alignment: .center) {
                if state == .active {
                    Capsule(style: .continuous).strokeBorder(Theme.brassLit.opacity(0.9), lineWidth: 1).padding(1.5)
                }
            }
    }
    @ViewBuilder private var badge: some View {
        switch state {
        case .done: badgeCircle(fill: Theme.sage, symbol: "✓")
        case .locked: badgeCircle(fill: Theme.locked, symbol: "🔒")
        case .active: EmptyView()
        }
    }
    private func badgeCircle(fill: Color, symbol: String) -> some View {
        Text(symbol).font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.cream)
            .frame(width: 26, height: 26)
            .background(Circle().fill(fill))
            .overlay(Circle().strokeBorder(Theme.cream.opacity(0.9), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            .offset(x: 8, y: -8)
    }
    @ViewBuilder private var gem: some View {
        if showGem {
            Text(state == .locked ? "📜" : "💎").font(.system(size: 22))
                .rotationEffect(.degrees(-12))
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .offset(x: -10, y: 12)
        }
    }
}

private struct GroundShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let hillTop = rect.height * 0.18
        p.move(to: CGPoint(x: rect.minX, y: hillTop))
        p.addQuadCurve(to: CGPoint(x: rect.midX, y: hillTop * 0.4), control: CGPoint(x: rect.width * 0.25, y: -hillTop * 0.4))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: hillTop), control: CGPoint(x: rect.width * 0.75, y: hillTop * 1.4))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: Bottom map tab bar

/// A small filled treasure-chest glyph (rounded lid + body with a seam gap + clasp),
/// tinted by the parent's foreground — used for the Treasures tab so the icon matches
/// the treasure theme instead of a generic box.
/// A single-tint treasure-chest icon that stays legible at nav-bar size. The key is
/// contrast within ONE color: a FILLED lid cap on top of a HOLLOW (outlined) body, so
/// the shape reads as a chest — not a solid blob — whether cream (inactive) or brass
/// (active) on the wood plank. A clasp + keyhole straddle the seam.
struct TreasureChestGlyph: View {
    var body: some View {
        GeometryReader { g in
            let w = g.size.width, h = g.size.height
            let lw = max(1.6, w * 0.085)          // outline weight
            let lidH = h * 0.40
            let bodyH = h * 0.60
            let rTop = w * 0.22
            let rBot = w * 0.10
            ZStack(alignment: .top) {
                // Body — hollow outline (lower ~60%), so wood shows through the chest.
                UnevenRoundedRectangle(topLeadingRadius: w * 0.04, bottomLeadingRadius: rBot,
                                       bottomTrailingRadius: rBot, topTrailingRadius: w * 0.04,
                                       style: .continuous)
                    .stroke(lineWidth: lw)
                    .frame(width: w - lw, height: bodyH - lw * 0.5)
                    .offset(y: lidH)

                // Lid — filled dome cap (top ~40%) with a hairline base band drawn by the
                // body outline meeting it, giving a clear lid/body seam.
                UnevenRoundedRectangle(topLeadingRadius: rTop, bottomLeadingRadius: 0,
                                       bottomTrailingRadius: 0, topTrailingRadius: rTop,
                                       style: .continuous)
                    .frame(width: w, height: lidH)

                // Clasp straddling the seam + a keyhole punched out of it.
                RoundedRectangle(cornerRadius: lw, style: .continuous)
                    .frame(width: w * 0.24, height: h * 0.34)
                    .overlay(alignment: .center) {
                        Circle()
                            .frame(width: w * 0.09, height: w * 0.09)
                            .blendMode(.destinationOut)
                            .offset(y: -h * 0.01)
                    }
                    .offset(y: lidH - h * 0.15)
            }
            .frame(width: w, height: h)
            .compositingGroup()                    // let the keyhole punch show the wood
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

enum MapTab: String, CaseIterable, Hashable {
    case map = "Map"
    case stories = "Stories"
    case treasures = "Treasures"
    case grownUps = "Grown-ups"
    var systemImage: String {
        switch self {
        case .map:       return "map"
        case .stories:   return "book.pages"
        case .treasures: return "shippingbox.fill"
        case .grownUps:  return "person.crop.circle"
        }
    }
}

struct MapTabBar: View {
    @Binding var selection: MapTab
    /// When true (the Map tab) the bar renders as a distinct carved-WOOD plank so it
    /// reads as a clear "shelf" separate from the parchment map above it. Other tabs
    /// keep the light parchment backing.
    var transparent: Bool = false
    /// Center action — opens Ask-Poli. Grown-ups action — the (gated) parent area.
    var onPoli: () -> Void = {}
    var onGrownUps: () -> Void = {}
    /// Bottom safe-area inset (home indicator), passed from HomeView. The plank
    /// background bleeds down through it to the very screen edge, while the button
    /// row is padded up by the same amount so it stays clear of the indicator.
    var bottomSafeInset: CGFloat = 0
    // The carved-wood plank art is the bar on every tab now, so icons always use the
    // on-wood (cream / brass) treatment.
    private var onWood: Bool { true }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            tabButton(for: .map)
            tabButton(for: .stories)
            // Center column reserves the middle 1/5 slot as empty space; the Poli
            // mascot is drawn as a top-anchored OVERLAY (below) so it can break above
            // the plank without making the bar taller AND without the offset-vs-hit-
            // target mismatch. Height is CAPPED — an uncapped Color.clear is greedy and
            // would balloon the bar (and its plank background) to full height.
            Color.clear.frame(maxWidth: .infinity).frame(height: 44)
            tabButton(for: .treasures)
            grownUpsButton
        }
        .padding(.horizontal, 8).padding(.top, 4).padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        // ONLY the wood background bleeds into the home-indicator area, so the plank is
        // always flush to the physical bottom on every device — while the button row
        // stays inside the safe area, just above the indicator. This replaces the old
        // measured-inset + `.clipped()` approach, which cropped the bleed on devices
        // where the passed-in inset didn't match (leaving a gap under the bar).
        .background(alignment: .top) {
            plankBackground.ignoresSafeArea(edges: .bottom)
        }
        .shadow(color: Theme.ink.opacity(0.3), radius: 8, x: 0, y: -3)
        // Poli overlays the center: horizontally centered, lifted above the board.
        // Overlays don't contribute to the HStack's height, so the bar stays put.
        .overlay(alignment: .top) { poliButton }
    }

    /// The plain carved-wood plank as a full-bleed bar background. The plank is a
    /// uniform horizontal wood grain (no frame / rounded ends), so we STRETCH it to
    /// fill the entire bar frame — including the home-indicator inset the bar bleeds
    /// into — leaving no parchment gap at any edge. Stretching horizontal grain is
    /// invisible; there are no corners to distort.
    private var plankBackground: some View {
        Image("NavPlank")
            .resizable(resizingMode: .stretch)
            .frame(maxWidth: .infinity)
    }

    /// The prominent center button: Poli's face — no disc, just the mascot — raised so
    /// it breaks ABOVE the plank (the only control that does), TikTok-style.
    ///
    /// It's an OVERLAY (see `body`), not an HStack child, which fixes two things:
    /// (1) it no longer makes the bar taller, and (2) the WHOLE visible mascot + its
    /// label is the tappable area. The old version drew the mascot with a big negative
    /// `.offset`, which moves pixels but NOT the hit target — so taps on the visible
    /// mascot (sitting high above its tiny layout slot) missed. The mascot + label
    /// VStack is now the real content shape, so any tap on Poli reliably opens Ask-Poli.
    private var poliButton: some View {
        Button(action: onPoli) {
            VStack(spacing: 2) {
                PoliImage(pose: .waving, size: 84)
                    .shadow(color: Theme.ink.opacity(0.35), radius: 5, x: 0, y: 3)
                Text("Ask Poli")
                    .font(Theme.navLabel(11, weight: .bold))
                    .foregroundStyle(iconColor(false))
                    .lineLimit(1)
                    .shadow(color: Color(hex: 0x2A180A, opacity: 0.5), radius: 1, x: 0, y: 1)
            }
            .padding(.horizontal, 26)   // generous horizontal tap margin around Poli
            .padding(.bottom, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(y: -40)                 // lift so the mascot breaks above the plank
        .accessibilityLabel("Ask Poli")
    }

    /// The parent dashboard ("Grown-ups") — now a real selectable TAB (it highlights
    /// when active), but tapping it still runs the biometric gate first (see HomeView's
    /// `onGrownUps`), so the grown-up must authenticate before the dashboard shows.
    private var grownUpsButton: some View {
        let isSelected = selection == .grownUps
        let tint = iconColor(isSelected)
        return Button(action: onGrownUps) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle().fill((onWood ? Theme.brassLit : Theme.brass).opacity(onWood ? 0.22 : 0.16))
                            .frame(width: 40, height: 40).blur(radius: 6)
                    }
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: isSelected ? 27 : 25, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(tint)
                        .shadow(color: isSelected ? (onWood ? Theme.brassLit : Theme.brass).opacity(0.6) : .clear,
                                radius: isSelected ? 6 : 0)
                        .shadow(color: onWood ? Color(hex: 0x2A180A, opacity: 0.5) : .clear, radius: 1, x: 0, y: 1)
                }
                .frame(height: 32)
                Text("Grown-ups")
                    .font(Theme.navLabel(isSelected ? 12.5 : 12, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .shadow(color: onWood ? Color(hex: 0x2A180A, opacity: 0.5) : .clear, radius: 1, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Grown-ups area")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // Wood palette (matches the map's carved wood-frame browns).
    private static let woodTop  = Color(hex: 0xB07C46)   // lit caramel
    private static let woodMid  = Color(hex: 0x7C4F2B)   // walnut
    private static let woodDeep = Color(hex: 0x4A2E17)   // dark brown

    /// Active tab → brass/gold; inactive → light cream (both legible on wood).
    private func iconColor(_ selected: Bool) -> Color {
        onWood ? (selected ? Theme.brassLit : Theme.cream)
               : (selected ? Theme.brass : Theme.inkSoft)
    }

    private func tabButton(for tab: MapTab) -> some View {
        let isSelected = selection == tab
        let tint = iconColor(isSelected)
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle().fill((onWood ? Theme.brassLit : Theme.brass).opacity(onWood ? 0.22 : 0.16))
                            .frame(width: 40, height: 40).blur(radius: 6)
                    }
                    Group {
                        if tab == .treasures {
                            // A single-tint chest glyph that matches the other line icons
                            // (the illustrated chest PNG is a full scene, unusable as a
                            // template icon — it just fills to a solid block).
                            TreasureChestGlyph()
                                .frame(width: isSelected ? 30 : 28, height: isSelected ? 30 : 28)
                                .foregroundStyle(tint)
                        } else {
                            Image(systemName: tab.systemImage)
                                .font(.system(size: isSelected ? 27 : 25, weight: isSelected ? .semibold : .regular))
                                .foregroundStyle(tint)
                        }
                    }
                    .shadow(color: isSelected ? (onWood ? Theme.brassLit : Theme.brass).opacity(0.6) : .clear,
                            radius: isSelected ? 6 : 0)
                    // On wood, a soft dark drop keeps light glyphs crisp against grain.
                    .shadow(color: onWood ? Color(hex: 0x2A180A, opacity: 0.5) : .clear, radius: 1, x: 0, y: 1)
                }
                .frame(height: 32)
                Text(tab.rawValue)
                    .font(Theme.navLabel(isSelected ? 12.5 : 12, weight: isSelected ? .bold : .regular))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .shadow(color: onWood ? Color(hex: 0x2A180A, opacity: 0.5) : .clear, radius: 1, x: 0, y: 1)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .scaleEffect(isSelected ? 1.08 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// The carved-wood plank: warm brown gradient + subtle vertical grain, a lit
    /// top bevel for clear separation from the map, extended under the safe area.
    private var woodBackground: some View {
        LinearGradient(colors: [Self.woodTop, Self.woodMid, Self.woodDeep],
                       startPoint: .top, endPoint: .bottom)
            .overlay(WoodGrain().opacity(0.5))
            .overlay(alignment: .top) {
                // Top bevel: bright brass highlight over a thin dark seam.
                VStack(spacing: 0) {
                    Rectangle().fill(Theme.brassLit.opacity(0.85)).frame(height: 1.5)
                    Rectangle().fill(Color(hex: 0xE7C98A, opacity: 0.28)).frame(height: 2)
                    Rectangle().fill(Color(hex: 0x2A180A, opacity: 0.45)).frame(height: 1)
                }
            }
            .compositingGroup()
            .shadow(color: Theme.ink.opacity(0.35), radius: 10, x: 0, y: -4)
            .ignoresSafeArea(edges: .bottom)
    }

    private var barBackground: some View {
        Theme.parchmentLit
            .overlay(alignment: .top) { Rectangle().fill(Theme.sepiaLine).frame(height: 1) }
            .shadow(color: Theme.ink.opacity(0.12), radius: 8, x: 0, y: -3)
            .ignoresSafeArea(edges: .bottom)
    }
}

/// Faint vertical wood-grain streaks (a few soft light/dark bands) drawn to fill.
private struct WoodGrain: View {
    var body: some View {
        Canvas { ctx, size in
            let cols: [(x: CGFloat, w: CGFloat, light: Bool)] = [
                (0.08, 2, false), (0.16, 1, true), (0.27, 3, false), (0.38, 1, true),
                (0.46, 2, false), (0.57, 1, true), (0.66, 3, false), (0.74, 1, true),
                (0.83, 2, false), (0.92, 1, true),
            ]
            for c in cols {
                let rect = CGRect(x: size.width * c.x, y: 0, width: c.w, height: size.height)
                let color = c.light ? Color(hex: 0xD9AE72, opacity: 0.35)
                                    : Color(hex: 0x35200F, opacity: 0.35)
                ctx.fill(Path(rect), with: .color(color))
            }
        }
        .blur(radius: 1.2)
        .allowsHitTesting(false)
    }
}
