import SwiftUI

struct MenuBarIcon: View {
    let blockCost: Double
    let blockLimit: Double

    private var fraction: Double {
        guard blockLimit > 0 else { return 0 }
        return blockCost / blockLimit
    }

    var body: some View {
        Image(systemName: iconName)
            .foregroundStyle(usageColor(for: fraction))
    }

    private var iconName: String {
        switch fraction {
        case ..<0.25: return "gauge.low"
        case ..<0.5: return "gauge.medium"
        case ..<0.75: return "gauge.medium"
        default: return "gauge.high"
        }
    }
}
