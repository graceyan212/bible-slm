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
        TrailStory(id: "creation",        title: "Creation",             cover: "CoverCreation"),
        TrailStory(id: "red_sea",         title: "The Red Sea",          cover: "CoverRedSea"),
        TrailStory(id: "jesus_children",  title: "Jesus & the Children", cover: "CoverJesusChildren"),
        TrailStory(id: "the_promise",     title: "The Promise",          cover: "CoverThePromise"),
        TrailStory(id: "jonah",           title: "Jonah & the Big Fish", cover: "StoryJonahP1"),
        TrailStory(id: "first_christmas", title: "The First Christmas",  cover: "StoryFirstChristmasP1"),
        TrailStory(id: "daniel_lions",    title: "Daniel & the Lions",   cover: "StoryDanielLionsP1"),
        TrailStory(id: "good_shepherd",   title: "The Good Shepherd",    cover: "StoryGoodShepherdP1"),
        TrailStory(id: "david_goliath",   title: "David & Goliath",      cover: "StoryDavidGoliathP1"),
        TrailStory(id: "easter",          title: "The First Easter",     cover: "StoryEasterP4"),
        TrailStory(id: "prodigal_son",    title: "The Father Who Ran",   cover: "StoryProdigalSonP3"),
        TrailStory(id: "zacchaeus",       title: "Zacchaeus",            cover: "StoryZacchaeusP1"),
    ]

    /// Trail state derived from the child's completed lessons: finished stops are
    /// `.done`, the FIRST unfinished stop is `.active` (the only new one you can
    /// open), and everything past it stays `.locked` until you reach it. Completing
    /// the active lesson therefore unlocks the next stop automatically.
    static func state(for index: Int, completed: Set<String>) -> PaintedStoryFrame.StopState {
        if completed.contains(all[index].id) { return .done }
        let firstIncomplete = all.firstIndex { !completed.contains($0.id) }
        return index == firstIncomplete ? .active : .locked
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
    /// Lessons the child has finished — drives done/active/locked (see StoryCatalog).
    var completed: Set<String> = []

    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20),
    ]

    var body: some View {
        ZStack {
            Theme.parchmentLit.ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    LazyVGrid(columns: columns, spacing: 26) {
                        ForEach(Array(StoryCatalog.all.enumerated()), id: \.element.id) { index, story in
                            let state = StoryCatalog.state(for: index, completed: completed)
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
        }
    }

    private var header: some View {
        ScreenTitle("Story Library", subtitle: "Every story on the trail, in order.")
    }
}

// (Story Library uses a plain light parchment background — see body above.)
