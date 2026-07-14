import SwiftUI
import BibleStoryCore

/// The calm, full-screen danger/crisis response (P7). Deliberately low-stimulation — no
/// cheerful map, no chat. It never counsels, never promises secrecy, never probes; it urges
/// a trusted grown-up and shows caregiver-facing resources.
///
/// ⚠️ All copy + resources here come from `CrisisFlowModel` / `CrisisResources`, which are
/// **SAFE PLACEHOLDERS** pending licensed child-safety sign-off (docs/SAFETY-AND-COPPA.md).
struct CrisisScreen: View {
    let resources: [CrisisResource]
    var onDone: () -> Void

    var body: some View {
        ZStack {
            Theme.parchmentLit.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 24)

                PoliImage(pose: .praying, size: 118)

                Text(CrisisFlowModel.childHeadline)
                    .font(Theme.display(28))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)

                Text(CrisisFlowModel.childBody)
                    .font(Theme.body(18))
                    .foregroundStyle(Theme.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Spacer(minLength: 12)

                Button(action: onDone) {
                    Text(CrisisFlowModel.showGrownUpLabel)
                        .font(Theme.body(20, weight: .bold))
                        .foregroundStyle(Theme.cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.brass, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 28)

                // Caregiver-facing help resources (a grown-up reads these).
                VStack(spacing: 4) {
                    Text("For a grown-up")
                        .font(Theme.body(12, weight: .bold))
                        .foregroundStyle(Theme.inkSoft)
                    ForEach(resources) { resource in
                        Text("\(resource.name) — \(resource.contact)")
                            .font(Theme.body(12))
                            .foregroundStyle(Theme.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .interactiveDismissDisabled(true)   // must tap "Show a grown-up" to leave
    }
}
