import SwiftUI
import UIKit

// =============================================================================
// MARK: - Painted Expedition map (real art)
// The `ExpeditionMap` asset is now a SEAMLESS, vertically-tiling treasure-map tile
// (design/build_seamless_map.py): its bottom edge flows into its top edge, so the
// backdrop repeats forever with no visible join and the trail can be any length.
// Each story stop is the ornate gold `StoryFrame` with its cover composited in.
// =============================================================================

/// The painted treasure map. Repeats the seamless tile vertically to fill whatever
/// height it's given (the trail grows with the story catalog). `muted` dims it with a
/// parchment veil so the colorful story covers pop — used behind the non-map tabs so
/// every screen shares the map's aesthetic.
struct PaintedMapBackdrop: View {
    var muted: Bool = false

    /// Computed ONCE (the asset is fixed per build) — avoids decoding the map image on
    /// every layout pass, which was a needless per-frame cost while scrolling.
    private static let tileAspect: CGFloat = {
        if let img = UIImage(named: "ExpeditionMap"), img.size.width > 0 {
            return img.size.height / img.size.width
        }
        return 1.266
    }()

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let tileH = max(1, w * Self.tileAspect)
            let count = max(1, Int(ceil(geo.size.height / tileH)) + 1)
            VStack(spacing: 0) {
                ForEach(0..<count, id: \.self) { _ in
                    Image("ExpeditionMap")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: tileH)
                        .clipped()
                }
            }
            .frame(width: w, height: geo.size.height, alignment: .top)
            .clipped()
            .overlay { if muted { Theme.parchment.opacity(0.55) } }
        }
        .allowsHitTesting(false)
    }
}

/// A single story "stop": the painted cover composited into the gold frame's
/// opening, the title on the ribbon, plus done/active/locked treatment.
struct PaintedStoryFrame: View {
    enum StopState { case done, active, locked }

    let coverAsset: String
    let title: String
    var state: StopState = .active
    var action: (() -> Void)? = nil

    // The `StoryFrame` PNG is 1104×974; the cover sits in this opening (fractions
    // of the frame), inset so the gold border stays fully visible around the art.
    private static let frameW: CGFloat = 1104
    private static let frameH: CGFloat = 974
    private static let opening = (l: 0.143, t: 0.200, r: 0.852, b: 0.716)
    private static let ribbonY: CGFloat = 0.855

    var body: some View {
        Group {
            if let action, state != .locked {
                Button(action: action) { frame }.buttonStyle(.plain)
            } else {
                frame
            }
        }
        .aspectRatio(Self.frameW / Self.frameH, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityText))
        .accessibilityAddTraits(state == .locked ? [] : .isButton)
    }

    private var accessibilityText: String {
        switch state {
        case .done:   return "\(title). Completed."
        case .active: return "\(title). Current story. Tap to begin."
        case .locked: return "\(title). Locked."
        }
    }

    private var frame: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let o = Self.opening
            let ox = w * o.l
            let oy = h * o.t
            let ow = w * (o.r - o.l)
            let oh = h * (o.b - o.t)

            ZStack(alignment: .topLeading) {
                if state == .active {
                    Circle()
                        .fill(activeGlow)
                        .frame(width: w * 1.3, height: w * 1.3)
                        .position(x: w * 0.5, y: h * 0.42)
                        .blur(radius: 3)
                        .allowsHitTesting(false)
                }

                // Gold frame first, then the cover composited into the opening
                // (the opening paper is opaque, so the cover sits ON TOP of it).
                Image("StoryFrame")
                    .resizable()
                    .frame(width: w, height: h)
                    .shadow(color: Color(hex: 0x32200C, opacity: 0.5), radius: 4, x: 0, y: 4)

                // Zoom the cover slightly so the illustration's own cream sky/margins are
                // cropped and the scene fills the frame opening (no white outline inside).
                Image(coverAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: ow, height: oh)
                    .clipped()
                    .scaleEffect(1.12)
                    .frame(width: ow, height: oh)
                    .clipped()
                    .offset(x: ox, y: oy)

                Text(title)
                    .font(Theme.display(w * 0.095))
                    .foregroundStyle(state == .active ? Color(hex: 0x7A4A12) : Color(hex: 0x4A3520))
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .frame(width: w * 0.74)
                    .position(x: w * 0.5, y: h * Self.ribbonY)

                badge(w: w, h: h)
            }
            .frame(width: w, height: h)
            .saturation(state == .locked ? 0.45 : 1)
            .opacity(state == .locked ? 0.72 : 1)
        }
    }

    private var activeGlow: RadialGradient {
        RadialGradient(
            stops: [
                .init(color: Color(hex: 0xFFD678, opacity: 0.9), location: 0.0),
                .init(color: Color(hex: 0xF3C34A, opacity: 0.34), location: 0.48),
                .init(color: Color(hex: 0xF3C34A, opacity: 0.0), location: 0.72),
            ],
            center: .center, startRadius: 0, endRadius: 130)
    }

    @ViewBuilder
    private func badge(w: CGFloat, h: CGFloat) -> some View {
        let d = w * 0.15
        switch state {
        case .done:
            badgeCircle(d: d, fill: Color(hex: 0x7E8B52), stroke: Color(hex: 0x5C6A3A), symbol: "checkmark")
                .position(x: w * 0.9, y: h * 0.12)
        case .locked:
            badgeCircle(d: d, fill: Color(hex: 0x8A7350), stroke: Color(hex: 0x6B5636), symbol: "lock.fill")
                .position(x: w * 0.9, y: h * 0.12)
        case .active:
            EmptyView()
        }
    }

    private func badgeCircle(d: CGFloat, fill: Color, stroke: Color, symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: d * 0.55, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: d, height: d)
            .background(Circle().fill(fill))
            .overlay(Circle().strokeBorder(stroke, lineWidth: max(1, d * 0.09)))
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
    }
}
