import Foundation

/// The family's chosen Bible translation (drives verse retrieval; see shared-interfaces P2).
public enum BibleTranslation: String, CaseIterable, Sendable, Codable {
    case nirv, icb, esv, niv, kjv

    public var displayName: String {
        switch self {
        case .nirv: "NIrV"
        case .icb: "ICB"
        case .esv: "ESV"
        case .niv: "NIV"
        case .kjv: "KJV"
        }
    }
}

/// A child profile ("explorer") under the parent account. `avatar` is the onboarding pick.
public struct ChildProfile: Identifiable, Sendable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var age: Int
    public var avatar: String   // emoji chosen at "pick your explorer"

    public init(id: UUID = UUID(), name: String, age: Int, avatar: String = "🦊") {
        self.id = id
        self.name = name
        self.age = age
        self.avatar = avatar
    }
}
