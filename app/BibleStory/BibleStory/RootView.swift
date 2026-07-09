import SwiftUI
import BibleStoryCore

/// Top-level router: onboarding (first-run) → child zone (Home) → parent zone (gated).
struct RootView: View {
    let env: AppEnvironment

    var body: some View {
        switch env.phase {
        case .onboarding:
            OnboardingView(env: env)
        case .child:
            HomeView(env: env)
        case .parent:
            ParentZoneView(env: env)
        }
    }
}
