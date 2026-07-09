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
        }
    }
}
