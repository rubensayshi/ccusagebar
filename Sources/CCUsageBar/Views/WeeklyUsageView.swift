import SwiftUI

struct WeeklyUsageView: View {
    let cost: Double
    let limit: Double

    private var fraction: Double { cost / limit }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("This Week")
                .font(.headline)

            HStack {
                Text("\(Fmt.currency(cost)) / \(Fmt.currency(limit))")
                    .font(.system(.body, design: .monospaced))
                Spacer()
                Text(Fmt.percentage(fraction))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(usageColor(for: fraction))
            }

            ProgressBarView(fraction: fraction)
        }
    }
}
