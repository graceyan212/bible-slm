import SwiftUI
import BibleStoryCore

@main
struct BibleStoryApp: App {
    @State private var appModel = AppModel(gate: BiometricParentGate())

    var body: some Scene {
        WindowGroup {
            RootView(appModel: appModel)
        }
    }
}
