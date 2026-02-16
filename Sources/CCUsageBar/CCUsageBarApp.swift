import SwiftUI

@main
struct CCUsageBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var service = UsageService()
    @AppStorage("blockLimit") private var blockLimit: Double = 43.50
    @AppStorage("weeklyLimit") private var weeklyLimit: Double = 717
    @AppStorage("weeklyResetDay") private var weeklyResetDay: Int = 4
    @AppStorage("weeklyResetHour") private var weeklyResetHour: Int = 9

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(service: service)
        } label: {
            MenuBarIcon(
                blockCost: service.data.activeBlock?.costUSD ?? 0,
                blockLimit: blockLimit,
                blockRemainingMinutes: service.data.activeBlock?.projection?.remainingMinutes,
                weeklyCost: service.data.weeklyCost,
                weeklyLimit: weeklyLimit,
                weeklyResetDay: weeklyResetDay,
                weeklyResetHour: weeklyResetHour
            )
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationService.shared.requestPermission()

        if !UserDefaults.standard.bool(forKey: "hasCompletedSetup") {
            SettingsWindowController.open()
        }
    }
}

enum SettingsWindowController {
    private static var window: NSWindow?

    static func open() {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    static func close() {
        window?.close()
        window = nil
    }
}
