import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("blockLimit") private var blockLimit: Double = 43.50
    @AppStorage("weeklyLimit") private var weeklyLimit: Double = 717
    @AppStorage("refreshInterval") private var refreshInterval: Int = 5
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("weeklyResetDay") private var weeklyResetDay: Int = 4
    @AppStorage("weeklyResetHour") private var weeklyResetHour: Int = 9
    @AppStorage("notifyAt50") private var notifyAt50 = true
    @AppStorage("notifyAt75") private var notifyAt75 = true
    @AppStorage("notifyAt90") private var notifyAt90 = true

    var body: some View {
        Form {
            Section("Limits") {
                HStack {
                    Text("Block limit")
                    Spacer()
                    TextField("$", value: $blockLimit, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("Weekly limit")
                    Spacer()
                    TextField("$", value: $weeklyLimit, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }
            }

            Section("Weekly Reset") {
                Picker("Day", selection: $weeklyResetDay) {
                    ForEach(ResetDay.allCases) { day in
                        Text(day.label).tag(day.rawValue)
                    }
                }
                Picker("Hour (UTC)", selection: $weeklyResetHour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d:00", h)).tag(h)
                    }
                }
            }

            Section("Refresh") {
                Picker("Interval", selection: $refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(interval.label).tag(interval.rawValue)
                    }
                }
            }

            Section("Notifications") {
                Toggle("At 50%", isOn: $notifyAt50)
                Toggle("At 75%", isOn: $notifyAt75)
                Toggle("At 90%", isOn: $notifyAt90)
            }

            Section("Advanced") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 500)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Launch at login error: \(error)")
            }
        }
    }
}
