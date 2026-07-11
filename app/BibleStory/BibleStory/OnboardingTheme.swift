import SwiftUI

// =============================================================================
//  Treasure Trail — Onboarding-local design system.
//
//  These are the SAME tokens as design/tokens.css + design/onboarding.html
//  (parchment palette, brass/gold candy buttons, storybook serif headings,
//  handwritten Poli voice, sepia map feel), re-expressed in SwiftUI.
//
//  Everything here is deliberately namespaced with an `Onb` prefix and kept in
//  THIS onboarding-only file so it never collides with the shared Components.swift
//  design system (Theme / PoliCompassView / …) when the branches merge. When the
//  shared Swift theme lands, these can be swapped for it 1:1 by find/replace.
//
//  No custom fonts are bundled in the project, so the storybook display serif is
//  approximated with the system serif and Poli's handwritten voice with a system
//  handwriting face (falls back gracefully). Colors are exact hex from tokens.css.
// =============================================================================

/// Build a Color from a 0xRRGGBB literal. Kept as a file-private free function
/// (not a `Color(hex:)` extension) so it can't clash with a hex initializer the
/// shared design system might also define.
private func onbColor(_ rgb: UInt, _ alpha: Double = 1) -> Color {
    Color(
        .sRGB,
        red: Double((rgb >> 16) & 0xFF) / 255,
        green: Double((rgb >> 8) & 0xFF) / 255,
        blue: Double(rgb & 0xFF) / 255,
        opacity: alpha
    )
}

// MARK: - Palette  (sampled from tokens.css :root)

enum OnbColors {
    static let parchment      = onbColor(0xF0E1C0) // main aged-paper field
    static let parchmentLit    = onbColor(0xFBF3E1) // lifted paper: cards / surface
    static let parchmentDeep   = onbColor(0xE4CFA1)
    static let sand           = onbColor(0xD8C08B) // locked / selected-tile fill
    static let ink            = onbColor(0x3B2E23) // body text (AAA on parchment)
    static let inkSoft         = onbColor(0x6E5A44) // secondary text
    static let sepiaLine       = onbColor(0xB79A6B) // map hairlines / dotted routes
    static let brass          = onbColor(0xD19A44) // primary CTA / active
    static let brassLit        = onbColor(0xEFCC7A)
    static let brassDeep       = onbColor(0x9A6B24) // engraved brass / glowing titles
    static let caramel        = onbColor(0xB0805A) // brand accent / milestone
    static let terracotta      = onbColor(0xC2683C) // campfire / ember
    static let sage           = onbColor(0x8FA79B) // done / secondary
    static let rose           = onbColor(0xD98E6A) // celebration
    static let locked         = onbColor(0xC3B08A)
    static let cream          = onbColor(0xFFF8EA)
    static let outline        = onbColor(0x3B2E23) // chunky sepia "ink" outline

    static let surface        = parchmentLit
    static let surfaceRead     = parchmentLit
    static let ctaInk          = outline           // dark ink on the brass CTA

    /// Ad-hoc hex color (e.g. avatar accents) without exposing a `Color(hex:)`
    /// extension that could collide with the shared design system at merge.
    static func custom(_ rgb: UInt, _ alpha: Double = 1) -> Color { onbColor(rgb, alpha) }
}

// MARK: - Type  (storybook serif display + clean body + handwritten Poli voice)

enum OnbFont {
    // Delegate to the shared design system (Components.swift `Theme`) so onboarding
    // uses the SAME real faces as the rest of the app: IM Fell English (display/caps),
    // Atkinson Hyperlegible (body), IM Fell English Italic (Poli's hand).
    static func display(_ size: CGFloat) -> Font { Theme.display(size) }
    static func title(_ size: CGFloat)   -> Font { Theme.display(size) }
    static func caps(_ size: CGFloat)    -> Font { Theme.mapCaps(size) }
    static func body(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { Theme.body(size, weight: weight) }
    static func hand(_ size: CGFloat) -> Font { Theme.hand(size) }
}

// MARK: - Parchment background  (mirrors body.starlight in tokens.css)

struct OnbBackground: View {
    var body: some View {
        GeometryReader { geo in
            let s = max(geo.size.width, geo.size.height)
            ZStack {
                OnbColors.parchment
                // soft light pooled at the top
                RadialGradient(
                    colors: [onbColor(0xFCF5E6), onbColor(0xFCF5E6, 0)],
                    center: UnitPoint(x: 0.5, y: -0.05), startRadius: 0, endRadius: s * 0.95
                )
                // warm brass pooled at the bottom
                RadialGradient(
                    colors: [OnbColors.brass.opacity(0.16), OnbColors.brass.opacity(0)],
                    center: UnitPoint(x: 0.5, y: 1.15), startRadius: 0, endRadius: s * 0.85
                )
                // gently darkened aged edges (vignette)
                RadialGradient(
                    colors: [onbColor(0x785426, 0), onbColor(0x785426, 0.16)],
                    center: .center, startRadius: s * 0.42, endRadius: s * 0.95
                )
            }
        }
        .ignoresSafeArea()
    }
}

/// Faint, static sepia map flecks — the ambient "starfield" from onboarding.html,
/// kept deterministic (no per-frame randomness) so it reads as journal texture.
struct OnbMapFlecks: View {
    private static let flecks: [(x: CGFloat, y: CGFloat, size: CGFloat, o: Double)] = [
        (0.08, 0.10, 12, 0.30), (0.22, 0.20, 8, 0.22), (0.86, 0.08, 14, 0.28),
        (0.70, 0.16, 9, 0.20), (0.14, 0.44, 10, 0.24), (0.92, 0.38, 11, 0.26),
        (0.06, 0.66, 9, 0.20), (0.80, 0.60, 13, 0.24), (0.32, 0.74, 8, 0.18),
        (0.60, 0.82, 12, 0.26), (0.18, 0.88, 10, 0.22), (0.90, 0.86, 9, 0.20),
        (0.46, 0.30, 8, 0.16), (0.50, 0.94, 10, 0.20),
    ]
    var body: some View {
        GeometryReader { geo in
            ForEach(Array(Self.flecks.enumerated()), id: \.offset) { _, f in
                Image(systemName: "sparkle")
                    .font(.system(size: f.size))
                    .foregroundStyle(OnbColors.sepiaLine)
                    .opacity(f.o)
                    .position(x: f.x * geo.size.width, y: f.y * geo.size.height)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Buttons  (fat, rounded, sticker-outlined, squishy — tokens.css .btn)

/// Brass gold primary CTA with the candy hard-offset "sticker" shadow + squish.
struct OnbPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(OnbFont.body(19, .bold))
            .foregroundStyle(OnbColors.ctaInk)
            .frame(maxWidth: .infinity, minHeight: 30)
            .padding(.vertical, 16)
            .padding(.horizontal, 28)
            .background(Capsule().fill(OnbColors.brass))
            .overlay(Capsule().stroke(OnbColors.outline, lineWidth: 3))
            .compositingGroup()
            .shadow(color: OnbColors.outline, radius: 0, x: 0, y: pressed ? 2 : 6)
            .offset(y: pressed ? 4 : 0)
            .opacity(isEnabled ? 1 : 0.45)
            .grayscale(isEnabled ? 0 : 0.4)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: pressed)
    }
}

/// Transparent caramel-outlined "ghost" button (secondary / skip).
struct OnbGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(OnbFont.body(16, .bold))
            .foregroundStyle(OnbColors.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .overlay(Capsule().stroke(OnbColors.caramel, lineWidth: 3))
            .offset(y: pressed ? 2 : 0)
            .opacity(pressed ? 0.7 : 1)
    }
}

// MARK: - Progress dots  (constellation route — tokens .dots)

struct OnbDots: View {
    let count: Int
    /// 1-based index of the current step; `count + 1` marks the finale (all lit).
    let current: Int

    var body: some View {
        ZStack {
            OnbDashLine()
                .stroke(OnbColors.sepiaLine,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [2, 6]))
                .frame(height: 3)
                .padding(.horizontal, 7)
                .opacity(0.6)
            HStack(spacing: 20) {
                ForEach(1...count, id: \.self) { i in
                    let lit = i <= current
                    Circle()
                        .fill(lit ? OnbColors.brass : OnbColors.surface)
                        .overlay(Circle().stroke(lit ? OnbColors.outline : OnbColors.locked, lineWidth: 2))
                        .frame(width: 14, height: 14)
                        .scaleEffect(i == current ? 1.35 : 1)
                        .shadow(color: lit ? OnbColors.brass.opacity(0.6) : .clear, radius: 6)
                        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: current)
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Setup progress")
        .accessibilityValue("Step \(min(current, count)) of \(count)")
    }
}

private struct OnbDashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

// MARK: - Poli's handwritten speech bubble  (parchment card + down tail)

struct OnbSpeechBubble: View {
    let text: String
    var body: some View {
        Text(text)
            .font(OnbFont.hand(23))
            .foregroundStyle(OnbColors.ink)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .padding(.vertical, 12)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: 22).fill(OnbColors.surfaceRead)
            )
            .overlay(alignment: .bottom) {
                OnbDownTail()
                    .fill(OnbColors.surfaceRead)
                    .frame(width: 26, height: 14)
                    .offset(y: 13)
            }
            .shadow(color: onbColor(0x5A3C19, 0.26), radius: 14, x: 0, y: 8)
            .accessibilityLabel("Poli says: \(text)")
    }
}

private struct OnbDownTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Trust promise row (grown-up card) & choice tile (avatar picker)

struct OnbPromiseRow: View {
    let icon: String
    let title: String
    let detail: String
    var tint: Color = OnbColors.brassDeep

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(OnbFont.body(17, .bold)).foregroundStyle(OnbColors.ink)
                Text(detail).font(OnbFont.body(15)).foregroundStyle(OnbColors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

struct OnbChoiceTile: View {
    let emoji: String
    let label: String
    let accent: Color
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 34))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle().fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.9), accent],
                                center: UnitPoint(x: 0.5, y: 0.35), startRadius: 2, endRadius: 40
                            )
                        )
                    )
                    .overlay(Circle().stroke(OnbColors.outline, lineWidth: 3))
                Text(label)
                    .font(OnbFont.body(15, .bold))
                    .foregroundStyle(selected ? OnbColors.brassDeep : OnbColors.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(selected ? OnbColors.sand : OnbColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(selected ? OnbColors.brass : OnbColors.outline,
                            lineWidth: selected ? 4 : 3)
            )
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(OnbColors.ctaInk)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(OnbColors.brass))
                        .overlay(Circle().stroke(OnbColors.outline, lineWidth: 3))
                        .offset(x: 8, y: -8)
                        .transition(.scale)
                }
            }
            .shadow(color: OnbColors.outline, radius: 0, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

/// A selectable translation chip (family Bible picker).
struct OnbChip: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(OnbFont.body(16, .bold))
                .foregroundStyle(selected ? OnbColors.ctaInk : OnbColors.ink)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(Capsule().fill(selected ? OnbColors.brass : OnbColors.surface))
                .overlay(Capsule().stroke(selected ? OnbColors.outline : OnbColors.sepiaLine,
                                          lineWidth: selected ? 3 : 2))
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: selected)
        .accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Poli — the trail-compass mascot
//
// Onboarding uses the SAME mascot as the rest of the app: the shared
// `PoliCompassView` (Components.swift). This thin wrapper keeps onboarding's
// height-based call sites while delegating to the one source of truth.

struct OnbPoli: View {
    var height: CGFloat = 220
    var body: some View {
        // PoliCompassView sizes by width (native 260×300); convert from height.
        PoliCompassView(size: height * 260.0 / 300.0)
    }
}
