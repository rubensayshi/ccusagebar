import SwiftUI

@main
struct CCUsageBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var service = UsageService()
    @AppStorage("blockLimit") private var blockLimit: Double = 43.50

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(service: service)
        } label: {
            MenuBarIcon(
                blockCost: service.data.activeBlock?.costUSD ?? 0,
                blockLimit: blockLimit
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
