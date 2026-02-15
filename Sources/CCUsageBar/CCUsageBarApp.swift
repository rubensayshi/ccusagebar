import SwiftUI

@main
struct CCUsageBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var service = UsageService()
    @AppStorage("blockLimit") private var blockLimit: Double = 43.50
    @AppStorage("weeklyLimit") private var weeklyLimit: Double = 717

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(service: service)
        } label: {
            MenuBarIcon(
                blockCost: service.data.activeBlock?.costUSD ?? 0,
                blockLimit: blockLimit,
                blockRemainingMinutes: service.data.activeBlock?.projection?.remainingMinutes,
                weeklyCost: service.data.weeklyCost,
                weeklyLimit: weeklyLimit
            )
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationService.shared.requestPermission()
    }
}
