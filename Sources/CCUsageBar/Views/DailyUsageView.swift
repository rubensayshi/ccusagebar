import SwiftUI

struct DailyUsageView: View {
    let cost: Double

    var body: some View {
        HStack {
            Text("Today")
                .font(.headline)
            Spacer()
            Text(Fmt.currency(cost))
                .font(.system(.body, design: .monospaced))
        }
    }
}
