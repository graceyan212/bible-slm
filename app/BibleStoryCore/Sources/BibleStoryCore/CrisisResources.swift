import Foundation

/// A crisis help resource shown to a grown-up (not the child) in the crisis screen.
public struct CrisisResource: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public let name: String
    public let contact: String
    public let note: String

    public init(id: UUID = UUID(), name: String, contact: String, note: String) {
        self.id = id
        self.name = name
        self.contact = contact
        self.note = note
    }
}

public enum CrisisResources {
    /// ⚠️ PLACEHOLDER — a licensed child-safety professional MUST confirm these numbers,
    /// localize them, and decide child-facing vs caregiver-facing placement before ship
    /// (docs/SAFETY-AND-COPPA.md §2.5). US examples only.
    public static let usPlaceholder: [CrisisResource] = [
        CrisisResource(name: "988 Suicide & Crisis Lifeline", contact: "988",
                       note: "Call or text, 24/7."),
        CrisisResource(name: "Childhelp National Child Abuse Hotline", contact: "1-800-422-4453",
                       note: "Call or text, 24/7, confidential."),
    ]
}
