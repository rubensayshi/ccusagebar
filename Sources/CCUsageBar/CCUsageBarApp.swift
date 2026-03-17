import SwiftUI

@main
struct CCUsageBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var service = UsageService()

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(service: service)
        } label: {
            MenuBarIcon(
                fiveHourUtilization: service.data.rateLimit?.fiveHour?.utilization ?? 0,
                sevenDayUtilization: service.data.rateLimit?.sevenDay?.utilization ?? 0,
                fiveHourResetsAt: service.data.rateLimit?.fiveHour?.resetsAt,
                sevenDayResetsAt: service.data.rateLimit?.sevenDay?.resetsAt
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
