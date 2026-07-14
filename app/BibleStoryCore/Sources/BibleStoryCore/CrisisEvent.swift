import Foundation

/// A record that a danger/crisis input was detected, surfaced (sanitized) to the parent
/// dashboard. **Privacy (COPPA):** `triggerSummary` is never the child's raw words — it is a
/// whitespace-collapsed, length-capped, neutral summary. See docs/SAFETY-AND-COPPA.md §2.6.
public struct CrisisEvent: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let childID: UUID
    public let createdAt: Date
    public let triggerSummary: String

    public init(id: UUID = UUID(), childID: UUID, createdAt: Date, triggerSummary: String) {
        self.id = id
        self.childID = childID
        self.createdAt = createdAt
        self.triggerSummary = triggerSummary
    }

    public static let maxSummaryLength = 140

    /// Collapse whitespace/newlines to single spaces, cap length, and return a neutral default
    /// for empty input — so a raw transcript can never persist verbatim.
    public static func sanitizedSummary(from reason: String) -> String {
        let collapsed = reason
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        guard !collapsed.isEmpty else { return "A sensitive topic came up." }
        guard collapsed.count > maxSummaryLength else { return collapsed }
        let end = collapsed.index(collapsed.startIndex, offsetBy: maxSummaryLength)
        return String(collapsed[..<end]) + "…"
    }
}
