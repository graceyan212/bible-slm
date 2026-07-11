import Foundation

// MARK: - Story Reader content model (data-driven from design/stories/<id>.json)
//
// Mirrors the finished creation.json (bundled under Content/). The narrative is a
// warm RETELL; the exact verse lives ONLY in `verse` (shown as retrieved from the
// family's Bible), and the story ends gospel-centered with `christConnection`. The
// treasure `reward` lands only at completion.

struct StoryContent: Decodable, Equatable {
    struct Page: Decodable, Equatable {
        let art: String
        let heading: String
        let text: String

        /// Bundled asset name for this page's art (JSON path → Assets.xcassets).
        var assetName: String { StoryContent.assetName(forArtPath: art) }
    }
    struct Verse: Decodable, Equatable {
        let ref: String
        let text: String
        let translation: String
    }
    struct Passage: Decodable, Equatable {
        let heading: String
        let text: String
    }
    struct Reward: Decodable, Equatable {
        let icon: String
        let name: String
        let text: String
    }

    let id: String
    let title: String
    let subtitle: String
    let pages: [Page]
    let verse: Verse
    let christConnection: Passage
    let reward: Reward

    enum CodingKeys: String, CodingKey {
        case id, title, subtitle, pages, verse, reward
        case christConnection = "christ_connection"
    }

    /// Maps a JSON art path (e.g. "story_creation/p1_light.png") to the bundled
    /// asset-catalog name. Falls back to a sanitized stem if unknown.
    static func assetName(forArtPath path: String) -> String {
        let stem = (path as NSString).lastPathComponent
            .replacingOccurrences(of: ".png", with: "")
        switch stem {
        case "p1_light":  return "StoryCreationP1"
        case "p2_world":  return "StoryCreationP2"
        case "p3_garden": return "StoryCreationP3"
        default:          return "StoryCreationP1"
        }
    }

    /// Loads a bundled story (e.g. "creation") from Content/<id>.json.
    static func load(_ id: String) -> StoryContent? {
        guard let url = Bundle.main.url(forResource: id, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(StoryContent.self, from: data)
    }
}
