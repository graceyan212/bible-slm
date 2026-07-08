import SwiftUI
import BibleStoryCore

/// Placeholder for the child experience (Story Library arrives in Plan P3).
/// The only way out to the parent area is through the gated button.
struct ChildZoneView: View {
    let appModel: AppModel

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer()
                Text("Story Library")
                    .font(.largeTitle)
                Spacer()
            }

            Button {
                Task { await appModel.enterParentZone() }
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                    .padding()
            }
            .accessibilityLabel("Parent area")
            .disabled(appModel.isAuthenticating)
        }
    }
}
