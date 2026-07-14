import Foundation
import UserNotifications
import BibleStoryCore

/// Posts a **local** notification asking a grown-up to open the parent area. Carries **no
/// transcript** — only a neutral prompt (privacy: docs/SAFETY-AND-COPPA.md §2.6). A remote
/// (APNs) path can replace this later; the app-agnostic core only knows the protocol.
struct LocalNotificationCrisisAlertService: CrisisAlertService {
    func alertCaregiver(_ event: CrisisEvent) async {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "A moment to check in"
        // Neutral — never the child's words or the trigger detail.
        content.body = "Something came up in True North that a grown-up should see. "
            + "Open the Grown-ups area when you can."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: event.id.uuidString,
            content: content,
            trigger: nil   // deliver now
        )
        try? await center.add(request)
    }
}
