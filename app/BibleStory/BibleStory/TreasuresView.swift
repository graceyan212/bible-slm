import SwiftUI

// MARK: - Treasures (collection) screen — the child's STAR sky + treasure shelf
//
// STARS are the hero and mean DAYS EXPLORED: every visit lights one golden star in the
// night sky, and a star is NEVER lost. This is deliberately NOT a streak — missing a day
// costs nothing — so there is no loss-aversion pressure (grounded in docs/research/06:
// streaks are flagged as manipulative for kids; a calm cumulative tally + "continue your
// journey" invitation is prescribed instead).
//
// TREASURES are the trophy side: story completions + milestones the child collects
// (collection mechanics are the lowest-risk, best-fit reward for ages 7-9). Grace-not-guilt:
// locked treasures invite ("keep exploring"), never shame.
//
// Data-driven from the bundled Content/treasures.json (schema mirrored in design/).

struct TreasuresData: Decodable {
    struct Treasure: Decodable, Identifiable {
        let name: String
        let from: String
        let emblem: String
        let earned: Bool
        let hint: String?
        var id: String { name }
        /// Earned treasures show where they came from; locked ones show the inviting hint.
        var subtitle: String { earned ? from : (hint ?? from) }
    }
    let daysExplored: Int
    let gems: Int
    let treasures: [Treasure]

    var treasuresFound: Int { treasures.filter(\.earned).count }
    var treasuresTotal: Int { treasures.count }

    static func load() -> TreasuresData? {
        guard let url = Bundle.main.url(forResource: "treasures", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TreasuresData.self, from: data)
    }
}

struct TreasuresView: View {
    private let data = TreasuresData.load()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        ZStack {
            PaintedMapBackdrop(muted: true).ignoresSafeArea()
            if let data {
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        SkyPanel(days: data.daysExplored)
                        journeyInvitation
                        pills(data)
                        treasureShelf(data)
                        Color.clear.frame(height: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
            } else {
                Text("Treasures unavailable")
                    .font(Theme.body(16)).foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 2) {
            Text("Your Night Sky")
                .font(Theme.display(32))
                .foregroundStyle(Theme.brassDeep)
            Text("A star lights up every day you explore")
                .font(Theme.body(14))
                .foregroundStyle(Theme.inkSoft)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
    }

    // MARK: Calm "continue your journey" invitation (replaces streak pressure)

    private var journeyInvitation: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 18)).foregroundStyle(Theme.brass)
            Text("Come back any day to light another star — you'll never lose one.")
                .font(Theme.body(14)).foregroundStyle(Theme.inkSoft)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.parchmentLit)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.sepiaLine.opacity(0.5), lineWidth: 1.5))
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: Secondary tallies — gems + treasures found

    private func pills(_ d: TreasuresData) -> some View {
        HStack(spacing: 12) {
            pill(icon: "diamond.fill", iconColor: Theme.sageDeep, text: "\(d.gems) gems")
            pill(icon: "trophy.fill", iconColor: Theme.brass,
                 text: "\(d.treasuresFound) of \(d.treasuresTotal) treasures")
        }
    }

    private func pill(icon: String, iconColor: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(iconColor)
            Text(text).font(Theme.body(15, weight: .bold)).foregroundStyle(Theme.ink)
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(Theme.parchmentDeep))
        .overlay(Capsule().strokeBorder(Theme.sand, lineWidth: 1))
    }

    // MARK: Treasure shelf (story completions + milestones)

    private func treasureShelf(_ d: TreasuresData) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Text("Treasures")
                    .font(Theme.display(22)).foregroundStyle(Theme.brassDeep)
                Rectangle().fill(Theme.sepiaLine.opacity(0.5)).frame(height: 1)
            }
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(d.treasures) { TreasureTile(treasure: $0) }
            }
        }
    }
}

// MARK: - Night-sky panel (the hero): one lit star per day explored

private struct SkyPanel: View {
    let days: Int
    @State private var twinkle = false

    private let radius: CGFloat = 22

    var body: some View {
        ZStack {
            // Night-sky field, framed in brass like the storybook cards.
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: 0x231A47), Color(hex: 0x2C2559), Color(hex: 0x3C2F66)],
                    startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color(hex: 0xE9B25A, opacity: 0.0), Color(hex: 0xE9B25A, opacity: 0.16)],
                        startPoint: .top, endPoint: .bottom)
                }

            starField

            // Hero tally, top-center (the star field is generated to leave this area clear).
            VStack(spacing: -2) {
                Text("\(days)")
                    .font(Theme.display(58))
                    .foregroundStyle(Color(hex: 0xFBE7A6))
                    .shadow(color: Color(hex: 0xF2B01F, opacity: 0.65), radius: 10)
                Text(days == 1 ? "star" : "stars")
                    .font(Theme.body(15, weight: .bold)).tracking(1)
                    .foregroundStyle(Color(hex: 0xF2DFA9))
                Text(days == 1 ? "1 day exploring" : "\(days) days exploring")
                    .font(Theme.body(12)).foregroundStyle(Color(hex: 0xC9BCE6))
                    .padding(.top, 2)
            }
            .padding(.top, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
        }
        .frame(height: 320)
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(LinearGradient(
                    colors: [Theme.brassLit, Theme.brass, Theme.brassDeep],
                    startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .inset(by: 5).strokeBorder(Theme.outline.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .shadow(color: Theme.ink.opacity(0.3), radius: 10, x: 0, y: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                twinkle = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your night sky. \(days) \(days == 1 ? "star" : "stars") lit — "
            + "one for every day you have explored. Stars are never lost.")
    }

    private var starField: some View {
        GeometryReader { geo in
            let dots = Self.layout(count: days, in: geo.size)
            ZStack {
                // Faint background stardust for depth.
                ForEach(0..<Self.dust.count, id: \.self) { i in
                    let d = Self.dust[i]
                    Circle().fill(Color.white.opacity(d.2))
                        .frame(width: d.3, height: d.3)
                        .position(x: geo.size.width * d.0, y: geo.size.height * d.1)
                }
                // One earned gold star per day explored.
                ForEach(dots) { dot in
                    StarMark(size: dot.size, isNewest: dot.isNewest,
                             glow: (twinkle ? 1.0 : 0.6) * dot.brightness)
                        .frame(width: dot.size + 10, height: dot.size + 10)
                        .position(dot.point)
                }
            }
        }
    }

    // MARK: Deterministic star layout (scales to any day count, stays clear of the tally)

    private struct StarDot: Identifiable {
        let id: Int
        let point: CGPoint
        let size: CGFloat
        let brightness: Double
        let isNewest: Bool
    }

    /// Deterministic scatter: stable across launches, avoids the top-center tally zone,
    /// varies size/brightness for a pretty twinkle. The last (newest) star is the biggest.
    private static func layout(count: Int, in size: CGSize) -> [StarDot] {
        guard count > 0, size.width > 0 else { return [] }
        let shown = min(count, 60)
        var gen = SeededGen(seed: 0x5EED_C0DE)
        var dots: [StarDot] = []
        let w = size.width, h = size.height
        // Tally occupies roughly the top-center; keep stars out of it.
        let exclude = CGRect(x: w * 0.30, y: 0, width: w * 0.40, height: h * 0.34)
        var i = 0
        var guardCount = 0
        // Keep stars from clustering: back the spacing off as the sky fills up.
        let minGap = max(28, min(w, h) / CGFloat(max(shown, 1)).squareRoot() * 0.7)
        while dots.count < shown && guardCount < shown * 60 {
            guardCount += 1
            let fx = 0.07 + gen.unit() * 0.86
            let fy = 0.12 + gen.unit() * 0.80
            let p = CGPoint(x: w * fx, y: h * fy)
            if exclude.insetBy(dx: -10, dy: -10).contains(p) { continue }
            if dots.contains(where: { hypot($0.point.x - p.x, $0.point.y - p.y) < minGap }) { continue }
            let sz = CGFloat(9 + gen.unit() * 9)          // 9–18pt
            let bright = 0.7 + gen.unit() * 0.3
            dots.append(StarDot(id: i, point: p, size: sz, brightness: bright, isNewest: false))
            i += 1
        }
        // Mark the most recently earned star (visually "today").
        if let last = dots.indices.last {
            let d = dots[last]
            dots[last] = StarDot(id: d.id, point: d.point, size: max(d.size, 17),
                                 brightness: 1, isNewest: true)
        }
        return dots
    }

    /// Faint background stardust: (x, y, opacity, diameter).
    private static let dust: [(Double, Double, Double, CGFloat)] = [
        (0.15, 0.14, 0.45, 2), (0.85, 0.18, 0.5, 2.2), (0.5, 0.5, 0.25, 1.6),
        (0.72, 0.8, 0.4, 2), (0.28, 0.84, 0.35, 1.6), (0.92, 0.55, 0.35, 1.8),
        (0.06, 0.62, 0.3, 1.4), (0.45, 0.92, 0.28, 1.6), (0.62, 0.42, 0.22, 1.4),
        (0.2, 0.5, 0.28, 1.5), (0.8, 0.4, 0.25, 1.4), (0.38, 0.68, 0.3, 1.6),
    ]
}

/// Small, fast, deterministic RNG so the sky looks the same every launch.
private struct SeededGen: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0xDEAD_BEEF : seed }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
    /// A Double in [0, 1).
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

// MARK: - A single lit gold star

private struct StarMark: View {
    var size: CGFloat = 14
    var isNewest: Bool = false
    var glow: Double = 1

    var body: some View {
        ZStack {
            StarShape()
                .fill(Color(hex: 0xFFE9A6))
                .frame(width: size * 1.7, height: size * 1.7)
                .blur(radius: 7)
                .opacity(0.5 * glow)
            if isNewest {
                Circle()
                    .stroke(Color(hex: 0xFBE7A6, opacity: 0.5), lineWidth: 1.2)
                    .frame(width: size * 2.1, height: size * 2.1)
            }
            StarShape()
                .fill(RadialGradient(
                    colors: [Color(hex: 0xFFF6DE), Color(hex: 0xF2B01F)],
                    center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: size * 0.62))
                .overlay(StarShape().stroke(Color(hex: 0xC98A1E), lineWidth: 0.8))
                .frame(width: size, height: size)
        }
    }
}

/// A classic five-pointed star.
struct StarShape: Shape {
    var points: Int = 5
    var innerRatio: CGFloat = 0.42

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let ri = r * innerRatio
        let n = points * 2
        for i in 0..<n {
            let angle = -CGFloat.pi / 2 + CGFloat(i) * .pi / CGFloat(points)
            let rad = i.isMultiple(of: 2) ? r : ri
            let point = CGPoint(x: c.x + cos(angle) * rad, y: c.y + sin(angle) * rad)
            if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - One treasure medallion (earned = gold, locked = dashed + grace hint)

private struct TreasureTile: View {
    let treasure: TreasuresData.Treasure

    var body: some View {
        VStack(spacing: 5) {
            medallion
            Text(treasure.earned ? treasure.name : "???")
                .font(Theme.body(13, weight: .bold))
                .foregroundStyle(treasure.earned ? Theme.ink : Theme.inkSoft)
                .multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
            Text(treasure.subtitle)
                .font(Theme.body(11))
                .foregroundStyle(Theme.caramel)
                .multilineTextAlignment(.center)
                .lineLimit(2).minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(treasure.earned
            ? "\(treasure.name), earned. From \(treasure.from)."
            : "Locked treasure. \(treasure.subtitle).")
    }

    private var emblemColor: Color { treasure.earned ? Theme.brassDeep : Theme.locked }

    private var medallion: some View {
        ZStack {
            Circle()
                .fill(treasure.earned
                      ? AnyShapeStyle(RadialGradient(
                          colors: [Theme.brassLit, Theme.brass],
                          center: UnitPoint(x: 0.5, y: 0.38), startRadius: 0, endRadius: 34))
                      : AnyShapeStyle(Theme.parchmentDeep))
                .frame(width: 68, height: 68)
                .overlay {
                    if treasure.earned {
                        Circle().strokeBorder(Theme.brassDeep, lineWidth: 2.5)
                    } else {
                        Circle().strokeBorder(Theme.sand,
                                              style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                    }
                }
                .shadow(color: treasure.earned ? Theme.brassDeep.opacity(0.35) : .clear,
                        radius: 2, x: 0, y: 2)

            emblem.frame(width: 38, height: 38)

            ZStack {
                Circle()
                    .fill(treasure.earned ? Theme.sageDeep : Theme.caramel)
                    .overlay(Circle().strokeBorder(Theme.parchment, lineWidth: 2))
                    .frame(width: 22, height: 22)
                Image(systemName: treasure.earned ? "checkmark" : "lock.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            .offset(x: 26, y: 26)
        }
        .frame(width: 72, height: 72)
    }

    @ViewBuilder private var emblem: some View {
        switch treasure.emblem {
        case "compass":
            CompassRose(color: emblemColor)
        default:
            Image(systemName: Self.symbol(for: treasure.emblem))
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(emblemColor)
        }
    }

    private static func symbol(for emblem: String) -> String {
        switch emblem {
        case "waves": return "water.waves"
        case "heart": return "heart.fill"
        case "dove":  return "bird.fill"
        case "boot":  return "shoeprints.fill"
        case "map":   return "map.fill"
        case "gem":   return "diamond.fill"
        case "sun":   return "sun.max.fill"
        case "crown": return "crown.fill"
        default:      return "star.fill"
        }
    }
}
