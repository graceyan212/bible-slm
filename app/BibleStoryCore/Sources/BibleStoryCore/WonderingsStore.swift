import Foundation
import Observation

/// A question Poli handed back to the grown-up (a DEFLECT), captured so the parent
/// can revisit it later in the Conversation Guide. Persisted on-device only.
public struct Wondering: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let question: String
    public let storyTitle: String
    public let date: Date

    public init(id: UUID = UUID(), question: String, storyTitle: String, date: Date) {
        self.id = id
        self.question = question
        self.storyTitle = storyTitle
        self.date = date
    }
}

/// Records the child's DEFLECT questions ("wonderings") for the parent. The behavior
/// pipeline flags these via `QuestionResponse.logToConversationGuide`; this store is
/// where they land. Newest first. On-device only (UserDefaults JSON) — nothing leaves
/// the device, consistent with the Parent Promise.
@MainActor
@Observable
public final class WonderingsStore {
    public private(set) var items: [Wondering] = []
    private let key = "wonderings.v1"

    public init() { load() }

    /// Append a deflected question (deduped against an identical most-recent entry).
    public func log(question: String, storyTitle: String, date: Date = Date()) {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        if items.first?.question == q { return }
        items.insert(Wondering(question: q, storyTitle: storyTitle, date: date), at: 0)
        save()
    }

    public func clear() { items = []; save() }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Wondering].self, from: data) else { return }
        items = decoded
    }
}
