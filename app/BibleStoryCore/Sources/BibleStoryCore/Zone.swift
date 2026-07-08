/// The two top-level areas of the app.
/// `.child` is the default, locked experience; `.parent` is gated.
public enum Zone: Sendable, Equatable {
    case child
    case parent
}
