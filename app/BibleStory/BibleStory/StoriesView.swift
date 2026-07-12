import SwiftUI

// =============================================================================
// MARK: - Story catalog (shared by the map trail + the Stories library)
// One ordered list is the single source of truth for what stories exist, in
// curriculum (chronological) order, and where the learner currently is. Add a
// new story here and it appears BOTH as a new stop on the map trail and as a
// new card in the library — no other edits needed.
// =============================================================================

struct TrailStory: Identifiable, Hashable {
    let id: String        // matches design/stories/<id>.json + StoryContent.load(id)
    let title: String
    let cover: String     // asset-catalog cover image name
}

enum StoryCatalog {
    /// Curriculum order. Append new stories here.
    static let all: [TrailStory] = [
        TrailStory(id: "creation",       title: "Creation",             cover: "CoverCreation"),
        TrailStory(id: "red_sea",        title: "The Red Sea",          cover: "CoverRedSea"),
        TrailStory(id: "jesus_children", title: "Jesus & the Children", cover: "CoverJesusChildren"),
        TrailStory(id: "the_promise",    title: "The Promise",          cover: "CoverThePromise"),
    ]

    /// The current (in-progress) story: everything before it is done, everything
    /// after it is still locked. (Wire this to real progress when available.)
    static let activeIndex = 2

    static func state(for index: Int) -> PaintedStoryFrame.StopState {
        if index < activeIndex { return .done }
        if index == activeIndex { return .active }
        return .locked
    }
}

// =============================================================================
// MARK: - Stories library (the "Stories" tab)
// A browsable shelf of every story cover, in curriculum order, with done /
// current / locked treatment. Tapping a done or current story opens its reader.
// =============================================================================

struct StoriesView: View {
    /// Open a story's reader by id (only called for done/current stories).
    var onOpen: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
    ]

    var body: some View {
        ZStack {
            MapBackdrop()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    LazyVGrid(columns: columns, spacing: 26) {
                        ForEach(Array(StoryCatalog.all.enumerated()), id: \.element.id) { index, story in
                            let state = StoryCatalog.state(for: index)
                            PaintedStoryFrame(coverAsset: story.cover, title: story.title, state: state) {
                                if state != .locked { onOpen(story.id) }
                            }
                        }
                    }
                    .padding(.horizontal, 26)
                }
                .padding(.top, 24)
                .padding(.bottom, 96)   // clear the pinned nav bar
            }
            MapBorderOverlay()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("Story Library")
                .font(Theme.display(34, weight: .black))
                .foregroundStyle(Theme.brassDeep)
            Text("Every story on the trail, in order.")
                .font(Theme.body(17))
                .foregroundStyle(Theme.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 30)
        .accessibilityElement(children: .combine)
    }
}
