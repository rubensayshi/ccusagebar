import SwiftUI

struct ProgressBarView: View {
    let fraction: Double
    var height: CGFloat = 8

    private var color: Color {
        usageColor(for: fraction)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geo.size.width * min(fraction, 1.0))
            }
        }
        .frame(height: height)
    }
}

func usageColor(for fraction: Double) -> Color {
    switch fraction {
    case ..<0.5: return .green
    case ..<0.75: return .yellow
    case ..<0.9: return .orange
    default: return .red
    }
}
