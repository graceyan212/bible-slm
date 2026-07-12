import SwiftUI
import BibleStoryCore

@main
struct BibleStoryApp: App {
    @State private var env = AppEnvironment(
        responder: StubQuestionResponder(),   // P5 swaps in the on-device model here
        gate: BiometricParentGate()
    )

    init() {
        AppFonts.register()   // register bundled IM Fell English / Atkinson faces
    }

    var body: some Scene {
        WindowGroup {
            // Dev/screenshot shortcut: `-uiPreviewReader` shows the Story Reader
            // directly (deterministic; avoids racing the onboarding transition).
            if ProcessInfo.processInfo.arguments.contains("-uiPreviewReader") {
                NavigationStack {
                    StoryView(env: env, storyID: ProcessInfo.processInfo.environment["STORY_ID"] ?? "creation")
                }
            } else if ProcessInfo.processInfo.arguments.contains("-uiPreviewAsk") {
                NavigationStack { CompassView(env: env) }
            } else {
                RootView(env: env)
                    .onAppear {
                        // `-uiPreviewChild` jumps past onboarding straight to the
                        // child-zone treasure map (dev/screenshot only).
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
}
