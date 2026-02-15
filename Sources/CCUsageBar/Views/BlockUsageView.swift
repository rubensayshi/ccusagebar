import SwiftUI

struct BlockUsageView: View {
    let block: Block
    let limit: Double

    private var fraction: Double { block.costUSD / limit }

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
                    .foregroundStyle(usageColor(for: fraction))
            }

            ProgressBarView(fraction: fraction)

            HStack {
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
