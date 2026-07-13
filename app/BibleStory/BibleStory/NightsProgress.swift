import SwiftUI

// =============================================================================
//  Nights together — the anti-streak.
//
//  Grace, not guilt: each night a story is completed lights one star, and the
//  count ONLY EVER GOES UP. Missing a night never resets, never penalizes, never
//  turns anything red. It captures the momentum benefit of a streak (progress you
//  can see) without the loss/anxiety mechanic the brand promises never to use.
//
//  No named patterns / constellations — just a fuller, brighter night sky (a
//  starry sky is wonder, not astrology; cf. Genesis 15:5).
// =============================================================================

enum NightsProgress {
    private static let countKey = "nights.count"
    private static let lastDayKey = "nights.lastDay"

    /// Total stars lit — the number of distinct nights a story was completed. Monotonic.
    static var count: Int { UserDefaults.standard.integer(forKey: countKey) }

    /// Light tonight's star, unless one was already lit today. Returns the new
    /// count and whether a fresh star was lit (false if already counted today).
    @discardableResult
    static func recordTonight(_ now: Date = Date(), _ calendar: Calendar = .current) -> (count: Int, lit: Bool) {
        let defaults = UserDefaults.standard
        let today = dayKey(now, calendar)
        if defaults.string(forKey: lastDayKey) == today {
            return (defaults.integer(forKey: countKey), false)   // already lit a star today
        }
        let newCount = defaults.integer(forKey: countKey) + 1
        defaults.set(newCount, forKey: countKey)
        defaults.set(today, forKey: lastDayKey)
        return (newCount, true)
    }

    /// A gentle milestone line when the count crosses a mark — celebration only,
    /// never a "don't lose it" warning. `nil` on non-milestone counts.
    static func milestone(_ count: Int) -> String? {
        switch count {
        case 1:  return "You lit your first star ✦"
        case 7:  return "A whole week of nights ✦"
        case 30: return "A month of stories together ✦"
        default: return (count > 0 && count % 50 == 0) ? "\(count) nights together ✦" : nil
        }
    }

    private static func dayKey(_ date: Date, _ calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }
}

// MARK: - Views (self-contained palette so this file never depends on a theme
//               file another session may be mid-edit on)

private enum Sky {
    static let gold   = Color(.sRGB, red: 0.82, green: 0.60, blue: 0.27, opacity: 1)   // brass
    static let star   = Color(.sRGB, red: 0.95, green: 0.82, blue: 0.42, opacity: 1)
    static let ink    = Color(.sRGB, red: 0.23, green: 0.18, blue: 0.14, opacity: 1)
    static let cream  = Color(.sRGB, red: 0.98, green: 0.95, blue: 0.88, opacity: 1)
}

/// Compact "N stars lit" pill — for a corner of the home map.
struct NightSkyBadge: View {
    let count: Int
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill").font(.system(size: 13)).foregroundStyle(Sky.gold)
            Text("\(count) \(count == 1 ? "star" : "stars") lit")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .foregroundStyle(Sky.ink)
        }
        .padding(.vertical, 7).padding(.horizontal, 13)
        .background(Capsule().fill(Sky.cream))
        .overlay(Capsule().stroke(Sky.gold.opacity(0.6), lineWidth: 1.5))
        .accessibilityLabel("\(count) stars lit — nights you've read together")
    }
}

/// A gentle night sky: `count` stars scattered deterministically (stable across
/// launches, no RNG), growing as nights accumulate. No named patterns.
struct NightSky: View {
    let count: Int
    var maxStars: Int = 60

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<min(max(count, 0), maxStars), id: \.self) { i in
                let p = Self.position(i)
                Image(systemName: i % 7 == 0 ? "sparkle" : "star.fill")
                    .font(.system(size: Self.size(i)))
                    .foregroundStyle(Sky.star)
                    .opacity(Self.opacity(i))
                    .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // Golden-ratio jitter → an even, organic-looking scatter with no clustering,
    // deterministic per index so the sky is stable every launch.
    private static func position(_ i: Int) -> CGPoint {
        CGPoint(x: 0.05 + frac(Double(i) * 0.61803398875) * 0.90,
                y: 0.05 + frac(Double(i) * 0.75487766625) * 0.90)
    }
    private static func size(_ i: Int) -> CGFloat { [8, 10, 12, 9, 11][i % 5] }
    private static func opacity(_ i: Int) -> Double { [0.55, 0.75, 0.95, 0.6, 0.85][i % 5] }
    private static func frac(_ v: Double) -> Double { v - v.rounded(.down) }
}
