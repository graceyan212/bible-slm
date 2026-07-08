import SwiftUI
import BibleStoryCore

/// Placeholder for the parent dashboard (built out in Plan P6).
struct ParentZoneView: View {
    let appModel: AppModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Parent Dashboard")
                .font(.largeTitle)
            Button("Return to Stories") {
                appModel.exitToChildZone()
            }
        }
    }
}
