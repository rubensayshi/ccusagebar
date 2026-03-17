import Foundation
import SwiftUI
import Combine

@MainActor
class UsageService: ObservableObject {
    @Published var data = UsageData()

    @AppStorage("refreshInterval") private var refreshIntervalMinutes: Int = 5

    private var timer: Timer?

    init() {
        startAutoRefresh()
    }

    func startAutoRefresh() {
        Task { await refresh() }
        scheduleTimer()
    }

    func scheduleTimer() {
        timer?.invalidate()
        let interval = TimeInterval(refreshIntervalMinutes * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refresh()
            }
        }
    }

    func refresh() async {
        data.isLoading = true
        data.error = nil

        let service = RateLimitService.shared
        let response = await service.fetchUsage()
        let meta = await service.readCredentialMeta()

        if let response {
            data.rateLimit = response

            // Notifications on 5h utilization
            if let fiveHour = response.fiveHour {
                NotificationService.shared.checkThresholds(utilization: fiveHour.utilization)
            }
        } else if meta == nil {
            data.error = "No credentials found in Keychain"
        } else {
            data.error = "Failed to fetch usage from API"
        }

        data.credentialMeta = meta
        data.lastUpdated = Date()

        writeStatusFile()

        data.isLoading = false
    }

    private func writeStatusFile() {
        var dict: [String: Any] = [
            "updated": ISO8601DateFormatter().string(from: Date()),
        ]

        if let rl = data.rateLimit {
            if let fh = rl.fiveHour {
                dict["five_hour"] = [
                    "utilization": fh.utilization,
                    "resets_at": fh.resetsAt ?? "",
                ]
            }
            if let sd = rl.sevenDay {
                dict["seven_day"] = [
                    "utilization": sd.utilization,
                    "resets_at": sd.resetsAt ?? "",
                ]
            }
            if let ss = rl.sevenDaySonnet {
                dict["seven_day_sonnet"] = [
                    "utilization": ss.utilization,
                    "resets_at": ss.resetsAt ?? "",
                ]
            }
        }

        if let meta = data.credentialMeta {
            dict["plan"] = [
                "tier": meta.rateLimitTier ?? "",
                "subscription": meta.subscriptionType ?? "",
            ]
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
        else { return }

        let target = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/usage-status.json")
        try? jsonData.write(to: target, options: .atomic)
    }
}
