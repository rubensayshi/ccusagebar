import Foundation
import UserNotifications

@MainActor
class NotificationService {
    static let shared = NotificationService()

    private var sentThresholds: Set<Int> = []
    private var available = false

    func requestPermission() {
        guard Bundle.main.bundleIdentifier != nil else {
            print("Notifications unavailable: no bundle ID (running outside .app)")
            return
        }
        available = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, error in
            if let error { print("Notification permission error: \(error)") }
        }
    }

    func checkThresholds(blockCost: Double, blockLimit: Double) {
        guard available, blockLimit > 0 else { return }
        let pct = blockCost / blockLimit

        let defaults = UserDefaults.standard
        let thresholds: [(Int, String)] = [
            (50, "notifyAt50"),
            (75, "notifyAt75"),
            (90, "notifyAt90"),
        ]

        for (level, key) in thresholds {
            let enabled = defaults.object(forKey: key) as? Bool ?? true
            if enabled && pct >= Double(level) / 100.0 && !sentThresholds.contains(level) {
                sentThresholds.insert(level)
                send(title: "CCUsageBar", body: "Block usage at \(level)%: \(Fmt.currency(blockCost)) / \(Fmt.currency(blockLimit))")
            }
        }
    }

    func resetForNewBlock() {
        sentThresholds.removeAll()
    }

    private func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
