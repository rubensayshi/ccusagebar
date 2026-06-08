import SwiftUI

struct WeeklyUsageView: View {
    let overall: WindowUtilization?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let overall {
                windowSection(label: "This Week", window: overall,
                              windowSeconds: WindowDuration.sevenDay)
            } else {
                HStack {
                    Text("No Weekly Data")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private func windowSection(label: String, window: WindowUtilization,
                               windowSeconds: TimeInterval) -> some View {
        let fraction = window.utilization / 100.0
        let timeFrac = timeFraction(resetsAt: window.resetsAt, windowSeconds: windowSeconds)

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
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
