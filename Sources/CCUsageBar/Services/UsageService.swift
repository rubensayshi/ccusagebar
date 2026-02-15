import Foundation
import SwiftUI
import Combine

@MainActor
class UsageService: ObservableObject {
    @Published var data = UsageData()

    @AppStorage("npxPath") private var npxPath = "npx"
    @AppStorage("blockLimit") private var blockLimit: Double = 43.50
    @AppStorage("refreshInterval") private var refreshIntervalMinutes: Int = 5

    private var timer: Timer?
    private var lastBlockId: String?

    private var npxCommand: String {
        npxPath.isEmpty ? "npx" : npxPath
    }

    init() {
        startAutoRefresh()
    }

    func startAutoRefresh() {
        // Initial fetch
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

        async let blockResult = fetchBlocks()
        async let dailyResult = fetchDaily()
        async let weeklyResult = fetchWeekly()

        let (block, daily, weekly) = await (blockResult, dailyResult, weeklyResult)

        if let b = block {
            // Detect new block → reset notifications
            if b.id != lastBlockId {
                lastBlockId = b.id
                NotificationService.shared.resetForNewBlock()
            }
            data.activeBlock = b
            NotificationService.shared.checkThresholds(blockCost: b.costUSD, blockLimit: blockLimit)
        } else {
            data.activeBlock = nil
        }

        if let d = daily { data.dailyCost = d }
        if let w = weekly { data.weeklyCost = w }

        // Only set error if ALL failed
        if block == nil && daily == nil && weekly == nil {
            data.error = data.error ?? "Failed to fetch usage data"
        }

        data.lastUpdated = Date()
        data.isLoading = false
    }

    private func fetchBlocks() async -> Block? {
        do {
            let json = try await ShellExecutor.run(
                "\(npxCommand) ccusage@latest blocks --active --json"
            )
            let response = try JSONDecoder().decode(BlocksResponse.self, from: Data(json.utf8))
            return response.blocks.first(where: { $0.isActive && !$0.isGap })
        } catch {
            print("Blocks fetch error: \(error)")
            if data.error == nil { data.error = error.localizedDescription }
            return nil
        }
    }

    private func fetchDaily() async -> Double? {
        let today = dateString(for: Date())
        do {
            let json = try await ShellExecutor.run(
                "\(npxCommand) ccusage@latest daily --since \(today) --json"
            )
            let response = try JSONDecoder().decode(DailyResponse.self, from: Data(json.utf8))
            return response.totals.totalCost
        } catch {
            print("Daily fetch error: \(error)")
            return nil
        }
    }

    private func fetchWeekly() async -> Double? {
        let monday = mondayString()
        do {
            let json = try await ShellExecutor.run(
                "\(npxCommand) ccusage@latest weekly --since \(monday) --json"
            )
            let response = try JSONDecoder().decode(WeeklyResponse.self, from: Data(json.utf8))
            return response.totals.totalCost
        } catch {
            print("Weekly fetch error: \(error)")
            return nil
        }
    }

    private func dateString(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: date)
    }

    private func mondayString() -> String {
        let cal = Calendar.current
        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        // .weekday: 1=Sun, 2=Mon, ..., 7=Sat
        let daysFromMonday = (weekday + 5) % 7
        let monday = cal.date(byAdding: .day, value: -daysFromMonday, to: today)!
        return dateString(for: monday)
    }
}
