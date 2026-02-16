import Foundation

enum BlockCalculator {

    private static let blockDuration: TimeInterval = 5 * 3600  // 5 hours
    private static let gapThreshold: TimeInterval = 5 * 3600   // 5h gap → new block

    struct BlockResult {
        let block: Block
        let dailyCost: Double
        let weeklyCost: Double
    }

    /// Compute active block, daily cost, and weekly cost from raw entries.
    static func compute(entries: [UsageEntry], now: Date = Date()) -> BlockResult {
        // Daily: entries from start of today (local time)
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: now)
        let dailyCost = entries
            .filter { $0.timestamp >= startOfDay }
            .reduce(0.0) { $0 + CostCalculator.cost(for: $1) }

        // Weekly: entries since Wednesday 09:00 UTC (Anthropic plan reset)
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        let utcWeekday = utcCal.component(.weekday, from: now) // 1=Sun..7=Sat, Wed=4
        let daysSinceWed = (utcWeekday - 4 + 7) % 7
        let startOfUTCDay = utcCal.startOfDay(for: now)
        var resetPoint = utcCal.date(byAdding: .day, value: -daysSinceWed, to: startOfUTCDay)!
        resetPoint = utcCal.date(bySettingHour: 9, minute: 0, second: 0, of: resetPoint)!
        if resetPoint > now { resetPoint = utcCal.date(byAdding: .day, value: -7, to: resetPoint)! }
        let weeklyCost = entries
            .filter { $0.timestamp >= resetPoint }
            .reduce(0.0) { $0 + CostCalculator.cost(for: $1) }

        // Blocks: group entries into 5h blocks separated by 5h gaps
        let activeBlock = findActiveBlock(entries: entries, now: now)

        return BlockResult(block: activeBlock, dailyCost: dailyCost, weeklyCost: weeklyCost)
    }

    private static func findActiveBlock(entries: [UsageEntry], now: Date) -> Block {
        // Walk entries in order, grouping by 5h gaps
        var blockEntries: [UsageEntry] = []
        var lastTimestamp: Date?

        for entry in entries {
            if let last = lastTimestamp, entry.timestamp.timeIntervalSince(last) > gapThreshold {
                // Gap detected — start new block
                blockEntries = []
            }
            blockEntries.append(entry)
            lastTimestamp = entry.timestamp
        }

        // Check if the latest block is still active
        guard let first = blockEntries.first,
              let last = blockEntries.last else {
            return noActiveBlock()
        }

        // Block start: floor to UTC hour
        let blockStart = floorToHour(first.timestamp)
        let blockEnd = blockStart.addingTimeInterval(blockDuration)

        // Active if: last entry within 5h AND now before block end
        let timeSinceLast = now.timeIntervalSince(last.timestamp)
        let isActive = timeSinceLast < gapThreshold && now < blockEnd

        guard isActive else { return noActiveBlock() }

        let totalTokens = blockEntries.reduce(0) { sum, e in
            sum + e.inputTokens + e.outputTokens + e.cacheCreationTokens + e.cacheReadTokens
        }
        let totalCost = blockEntries.reduce(0.0) { $0 + CostCalculator.cost(for: $1) }
        let models = Array(Set(blockEntries.map(\.model)))

        let elapsedSeconds = now.timeIntervalSince(blockStart)
        let elapsedMinutes = max(elapsedSeconds / 60, 1)
        let elapsedHours = max(elapsedSeconds / 3600, 1.0 / 60)

        let tokensPerMinute = Double(totalTokens) / elapsedMinutes
        let costPerHour = totalCost / elapsedHours

        let remainingSeconds = blockEnd.timeIntervalSince(now)
        let remainingMinutes = max(Int(remainingSeconds / 60), 0)

        // Project to full 5h window
        let blockTotalSeconds = blockDuration
        let projectedTokens = Int(tokensPerMinute * (blockTotalSeconds / 60))
        let projectedCost = costPerHour * (blockTotalSeconds / 3600)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        return Block(
            id: isoFormatter.string(from: blockStart),
            startTime: isoFormatter.string(from: blockStart),
            endTime: isoFormatter.string(from: blockEnd),
            isActive: true,
            isGap: false,
            totalTokens: totalTokens,
            costUSD: totalCost,
            models: models,
            burnRate: BurnRate(
                tokensPerMinute: tokensPerMinute,
                costPerHour: costPerHour
            ),
            projection: Projection(
                totalTokens: projectedTokens,
                totalCost: projectedCost,
                remainingMinutes: remainingMinutes
            )
        )
    }

    private static func noActiveBlock() -> Block {
        Block(
            id: "none",
            startTime: "",
            endTime: "",
            isActive: false,
            isGap: true,
            totalTokens: 0,
            costUSD: 0,
            models: [],
            burnRate: nil,
            projection: nil
        )
    }

    private static func floorToHour(_ date: Date) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: date)
        return cal.date(from: comps)!
    }
}
