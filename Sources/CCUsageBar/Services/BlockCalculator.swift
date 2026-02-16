import Foundation

enum BlockCalculator {

    private static let blockDuration: TimeInterval = 5 * 3600  // 5 hours

    struct BlockResult {
        let block: Block
        let dailyCost: Double
        let weeklyCost: Double
    }

    /// Compute active block, daily cost, and weekly cost from raw entries.
    static func compute(entries: [UsageEntry], resetDay: Int = 4, resetHour: Int = 9, now: Date = Date()) -> BlockResult {
        // Daily: entries from start of today (local time)
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: now)
        let dailyCost = entries
            .filter { $0.timestamp >= startOfDay }
            .reduce(0.0) { $0 + CostCalculator.cost(for: $1) }

        // Weekly: entries since configured reset point
        let resetPoint = weeklyResetPoint(resetDay: resetDay, resetHour: resetHour, before: now)
        let weeklyCost = entries
            .filter { $0.timestamp >= resetPoint }
            .reduce(0.0) { $0 + CostCalculator.cost(for: $1) }

        // Blocks: group entries into 5h blocks separated by 5h gaps
        let activeBlock = findActiveBlock(entries: entries, now: now)

        return BlockResult(block: activeBlock, dailyCost: dailyCost, weeklyCost: weeklyCost)
    }

    private static func findActiveBlock(entries: [UsageEntry], now: Date) -> Block {
        // Sequential blocks: each starts on first activity (floored to UTC hour),
        // lasts blockDuration. Next block starts on first activity after previous expires.
        var blockStart: Date?
        var blockEnd: Date?
        var blockEntries: [UsageEntry] = []

        for entry in entries {
            if let end = blockEnd, entry.timestamp >= end {
                // Previous block expired — new block on this activity
                blockStart = floorToHour(entry.timestamp)
                blockEnd = blockStart!.addingTimeInterval(blockDuration)
                blockEntries = [entry]
            } else if blockStart == nil {
                // First ever entry — start first block
                blockStart = floorToHour(entry.timestamp)
                blockEnd = blockStart!.addingTimeInterval(blockDuration)
                blockEntries = [entry]
            } else {
                blockEntries.append(entry)
            }
        }

        guard let start = blockStart, let end = blockEnd else {
            return noActiveBlock()
        }

        // Active if now is within the current block window
        guard now >= start && now < end else { return noActiveBlock() }

        let totalTokens = blockEntries.reduce(0) { sum, e in
            sum + e.inputTokens + e.outputTokens + e.cacheCreationTokens + e.cacheReadTokens
        }
        let totalCost = blockEntries.reduce(0.0) { $0 + CostCalculator.cost(for: $1) }
        let models = Array(Set(blockEntries.map(\.model)))

        let elapsedSeconds = now.timeIntervalSince(start)
        let elapsedMinutes = max(elapsedSeconds / 60, 1)
        let elapsedHours = max(elapsedSeconds / 3600, 1.0 / 60)

        let tokensPerMinute = Double(totalTokens) / elapsedMinutes
        let costPerHour = totalCost / elapsedHours

        let remainingSeconds = end.timeIntervalSince(now)
        let remainingMinutes = max(Int(remainingSeconds / 60), 0)

        // Project to full 5h window
        let blockTotalSeconds = blockDuration
        let projectedTokens = Int(tokensPerMinute * (blockTotalSeconds / 60))
        let projectedCost = costPerHour * (blockTotalSeconds / 3600)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        return Block(
            id: isoFormatter.string(from: start),
            startTime: isoFormatter.string(from: start),
            endTime: isoFormatter.string(from: end),
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
