import SwiftUI

struct BlockUsageView: View {
    let window: WindowUtilization

    private var fraction: Double { window.utilization / 100.0 }

    private var timeFrac: Double {
        timeFraction(resetsAt: window.resetsAt, windowSeconds: WindowDuration.fiveHour)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("5-Hour Window")
                    .font(.headline)
                Spacer()
                Text(Fmt.countdown(until: window.resetsAt))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(Fmt.utilization(window.utilization))
                    .font(.system(.body, design: .monospaced))
                Spacer()
                Text(paceLabel(usage: fraction, time: timeFrac))
                    .font(.caption)
                    .foregroundStyle(paceColor(usage: fraction, time: timeFrac))
            }

            ProgressBarView(fraction: fraction, timeFraction: timeFrac)
        }
    }
}
