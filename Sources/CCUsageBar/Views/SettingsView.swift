import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("hasCompletedSetup") private var hasCompletedSetup = false
    @AppStorage("refreshInterval") private var refreshInterval: Int = 5
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("notifyAt50") private var notifyAt50 = true
    @AppStorage("notifyAt75") private var notifyAt75 = true
    @AppStorage("notifyAt90") private var notifyAt90 = true

    private var isSetupMode: Bool { !hasCompletedSetup }

    var body: some View {
        Form {
            if isSetupMode {
                Section {
                    VStack(spacing: 8) {
                        Text("Welcome to CCUsageBar")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Usage data is fetched from the Anthropic API via your Claude Code credentials.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
            }

            Section("Refresh") {
                Picker("Interval", selection: $refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text(interval.label).tag(interval.rawValue)
                    }
                }
            }

            if !isSetupMode {
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

            if isSetupMode {
                Section {
                    Button("Get Started") {
                        hasCompletedSetup = true
                        SettingsWindowController.close()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: isSetupMode ? 300 : 350)
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
