import SwiftUI
import BibleStoryCore

struct RootView: View {
    let appModel: AppModel

    var body: some View {
        switch appModel.zone {
        case .child:
            ChildZoneView(appModel: appModel)
        case .parent:
            ParentZoneView(appModel: appModel)
        }
    }
}
