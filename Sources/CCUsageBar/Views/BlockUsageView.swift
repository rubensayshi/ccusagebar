import SwiftUI

struct BlockUsageView: View {
    let block: Block
    let limit: Double

    private let blockTotalMinutes: Double = 300 // 5h window

    private var fraction: Double { block.costUSD / limit }

    private var timeFraction: Double {
        guard let remaining = block.projection?.remainingMinutes else { return 0 }
        let elapsed = blockTotalMinutes - Double(remaining)
        return min(max(elapsed / blockTotalMinutes, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Current Block")
                    .font(.headline)
                Spacer()
                if let proj = block.projection {
                    Text(Fmt.timeRemaining(minutes: proj.remainingMinutes))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("\(Fmt.currency(block.costUSD)) / \(Fmt.currency(limit))")
                    .font(.system(.body, design: .monospaced))
                Spacer()
                Text(Fmt.percentage(fraction))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(paceColor(usage: fraction, time: timeFraction))
            }

            ProgressBarView(fraction: fraction, timeFraction: timeFraction)

            HStack {
                Text(paceLabel(usage: fraction, time: timeFraction))
                    .font(.caption)
                    .foregroundStyle(paceColor(usage: fraction, time: timeFraction))
                Spacer()
                if let rate = block.burnRate {
                    Text("Burn: \(Fmt.burnRate(rate.costPerHour))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let proj = block.projection {
                    Text("Proj: \(Fmt.currency(proj.totalCost))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
