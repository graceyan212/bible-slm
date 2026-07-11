import SwiftUI

// MARK: - Treasures (collection) screen — design/treasures.html
//
// The gamified reward layer, kept separate from the sacred story: painted chest
// hero + "found X of Y" + a medallion grid (earned = gold, locked = muted + lock
// with grace-not-guilt hints). Data-driven from the bundled Content/treasures.json.

struct TreasuresData: Decodable {
    struct Item: Decodable, Identifiable {
        let name: String
        let from: String
        let emblem: String
        let earned: Bool
        let hint: String?
        var id: String { name }
        /// Earned tiles show what they're from; locked tiles show the inviting hint.
        var subtitle: String { earned ? from : (hint ?? from) }
    }
    struct Section: Decodable, Identifiable {
        let title: String
        let items: [Item]
        var id: String { title }
    }
    let found: Int
    let total: Int
    let streak: Int
    let gems: Int
    let sections: [Section]

    static func load() -> TreasuresData? {
        guard let url = Bundle.main.url(forResource: "treasures", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TreasuresData.self, from: data)
    }
}

struct TreasuresView: View {
    private let data = TreasuresData.load()
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    var body: some View {
        ZStack {
            Color(hex: 0xF6EDD7).ignoresSafeArea()
            if let data {
                ScrollView {
                    VStack(spacing: 0) {
                        hero(data)
                        pills(data)
                        ForEach(data.sections) { section in
                            sectionView(section)
                        }
                        Color.clear.frame(height: 10)
                    }
                }
            } else {
                Text("Treasures unavailable")
                    .font(Theme.body(16)).foregroundStyle(Theme.inkSoft)
            }
        }
    }

    // MARK: Hero

    private func hero(_ d: TreasuresData) -> some View {
        Image("TreasureChest")
            .resizable()
            .scaledToFill()
            .frame(height: 186)
            .frame(maxWidth: .infinity)
            .clipped()
            .overlay(
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: 0x28190A, opacity: 0.05), location: 0.4),
                        .init(color: Color(hex: 0x28190A, opacity: 0.65), location: 1.0),
                    ],
                    startPoint: .top, endPoint: .bottom)
            )
            .overlay(alignment: .bottom) {
                VStack(spacing: 1) {
                    Text("Treasures")
                        .font(Theme.display(27))
                        .foregroundStyle(Color(hex: 0xFBF3DC))
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 2)
                    Text("\(d.found) of \(d.total) found")
                        .font(Theme.body(11, weight: .bold)).tracking(0.5)
                        .foregroundStyle(Color(hex: 0xF2DFA9))
                }
                .padding(.bottom, 10)
            }
    }

    private func pills(_ d: TreasuresData) -> some View {
        HStack(spacing: 10) {
            pill(icon: "flame.fill", iconColor: Color(hex: 0xE8802B), text: "\(d.streak)-day streak")
            pill(icon: "diamond.fill", iconColor: Color(hex: 0x3F8FBF), text: "\(d.gems) gems")
        }
        .padding(.top, 10).padding(.bottom, 4)
    }

    private func pill(icon: String, iconColor: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(iconColor)
            Text(text).font(Theme.body(12, weight: .bold)).foregroundStyle(Color(hex: 0x6B4A2A))
        }
        .padding(.horizontal, 11).padding(.vertical, 5)
        .background(Capsule().fill(Color(hex: 0xEFE0BE)))
        .overlay(Capsule().strokeBorder(Color(hex: 0xD6BD88), lineWidth: 1))
    }

    // MARK: Section + grid

    private func sectionView(_ section: TreasuresData.Section) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 7) {
                Text(section.title)
                    .font(Theme.display(17)).foregroundStyle(Color(hex: 0x7A4A12))
                Rectangle().fill(Color(hex: 0xD8C39A)).frame(height: 1)
            }
            .padding(.top, 8)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(section.items) { item in
                    TreasureTile(item: item)
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 14)
    }
}

/// One medallion tile: emblem + earned/locked treatment + name + hint.
private struct TreasureTile: View {
    let item: TreasuresData.Item

    var body: some View {
        VStack(spacing: 3) {
            medallion
            Text(item.earned ? item.name : "???")
                .font(Theme.body(9, weight: .bold))
                .foregroundStyle(item.earned ? Color(hex: 0x5B4630) : Color(hex: 0x9A8763))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(item.subtitle)
                .font(Theme.body(7.5, weight: .bold))
                .foregroundStyle(Color(hex: 0xA2895F))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibility))
    }

    private var accessibility: String {
        item.earned
            ? "\(item.name), earned. From \(item.from)."
            : "Locked treasure. \(item.subtitle)."
    }

    private var medallion: some View {
        ZStack {
            Circle()
                .fill(item.earned
                      ? AnyShapeStyle(RadialGradient(colors: [Color(hex: 0xFBE7A6), Color(hex: 0xD9A94E)],
                                                     center: UnitPoint(x: 0.5, y: 0.38), startRadius: 0, endRadius: 34))
                      : AnyShapeStyle(Color(hex: 0xE4D6B4)))
                .frame(width: 58, height: 58)
                .overlay {
                    if item.earned {
                        Circle().strokeBorder(Color(hex: 0xB07E2C), lineWidth: 2.5)
                    } else {
                        Circle().strokeBorder(Color(hex: 0xC3AC7D),
                                              style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                    }
                }
                .shadow(color: item.earned ? Color(hex: 0x5A3C14, opacity: 0.35) : .clear,
                        radius: 2, x: 0, y: 2)

            emblem
                .frame(width: 32, height: 32)

            badge
        }
        .frame(width: 62, height: 62)
    }

    private var emblemColor: Color { item.earned ? Color(hex: 0x6E4514) : Color(hex: 0xB6A480) }

    @ViewBuilder private var emblem: some View {
        switch item.emblem {
        case "compass":
            CompassRose(color: emblemColor)
        default:
            Image(systemName: Self.symbol(for: item.emblem))
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(emblemColor)
        }
    }

    private static func symbol(for emblem: String) -> String {
        switch emblem {
        case "waves":  return "water.waves"
        case "heart":  return "heart.fill"
        case "dove":   return "bird.fill"
        case "boot":   return "shoeprints.fill"
        case "flame":  return "flame.fill"
        case "map":    return "map.fill"
        case "gem":    return "diamond.fill"
        case "sun":    return "sun.max.fill"
        case "crown":  return "crown.fill"
        default:       return "star.fill"
        }
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(item.earned ? Color(hex: 0x7E8B52) : Color(hex: 0x8A7350))
                .overlay(Circle().strokeBorder(Color(hex: 0xF6EDD7), lineWidth: 2))
                .frame(width: 19, height: 19)
            Image(systemName: item.earned ? "checkmark" : "lock.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
        }
        .offset(x: 22, y: 22)
    }
}
