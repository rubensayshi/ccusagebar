import Foundation
import SwiftUI
import Combine

@MainActor
class UsageService: ObservableObject {
    @Published var data = UsageData()

    @AppStorage("blockLimit") private var blockLimit: Double = CostCalculator.defaultBlockLimit
    @AppStorage("refreshInterval") private var refreshIntervalMinutes: Int = 5
    @AppStorage("weeklyResetDay") private var weeklyResetDay: Int = 4   // Wed
    @AppStorage("weeklyResetHour") private var weeklyResetHour: Int = 9 // 09:00 UTC

    private var timer: Timer?
    private var lastBlockId: String?

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

        let entries = await Task.detached(priority: .userInitiated) {
            JSONLReader.scan()
        }.value

        let result = BlockCalculator.compute(entries: entries, resetDay: weeklyResetDay, resetHour: weeklyResetHour)

        if result.block.isActive && !result.block.isGap {
            if result.block.id != lastBlockId {
                lastBlockId = result.block.id
                NotificationService.shared.resetForNewBlock()
            }
            data.activeBlock = result.block
            NotificationService.shared.checkThresholds(blockCost: result.block.costUSD, blockLimit: blockLimit)
        } else {
            data.activeBlock = nil
        }

        data.dailyCost = result.dailyCost
        data.weeklyCost = result.weeklyCost
        data.lastUpdated = Date()

        writeStatusFile(block: data.activeBlock, dailyCost: result.dailyCost, weeklyCost: result.weeklyCost)

        data.isLoading = false
    }

    private func writeStatusFile(block: Block?, dailyCost: Double, weeklyCost: Double) {
        var dict: [String: Any] = [
            "daily": ["cost": dailyCost],
            "weekly": ["cost": weeklyCost, "limit": CostCalculator.defaultWeeklyLimit,
                       "pct": round(weeklyCost / CostCalculator.defaultWeeklyLimit * 1000) / 10],
            "updated": ISO8601DateFormatter().string(from: Date()),
        ]

        if let b = block {
            let pct = round(b.costUSD / blockLimit * 1000) / 10
            var blockDict: [String: Any] = [
                "cost": round(b.costUSD * 100) / 100,
                "limit": blockLimit,
                "pct": pct,
                "active": true,
            ]
            if let proj = b.projection {
                blockDict["remaining_min"] = proj.remainingMinutes
            }
            if let burn = b.burnRate {
                blockDict["burn_rate"] = round(burn.costPerHour * 100) / 100
            }
            dict["block"] = blockDict
        } else {
            dict["block"] = ["active": false]
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
        else { return }

        let target = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/usage-status.json")
        try? jsonData.write(to: target, options: .atomic)
    }
}
