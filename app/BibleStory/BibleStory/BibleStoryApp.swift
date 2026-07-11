import SwiftUI
import BibleStoryCore

@main
struct BibleStoryApp: App {
    @State private var env = AppEnvironment(
        responder: StubQuestionResponder(),   // P5 swaps in the on-device model here
        gate: BiometricParentGate()
    )

    var body: some Scene {
        WindowGroup {
            RootView(env: env)
                .onAppear {
                    // UI-preview shortcut: `-uiPreviewChild` jumps past onboarding
                    // straight to the child-zone treasure map (dev/screenshot only).
                    if ProcessInfo.processInfo.arguments.contains("-uiPreviewChild") {
                        env.completeOnboarding(
                            child: ChildProfile(name: "Explorer", age: 8),
                            translation: .nirv
                        )
                    }
                }
        }
    }
}
