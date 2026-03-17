import Foundation

enum RefreshInterval: Int, CaseIterable, Identifiable {
    case one = 1
    case two = 2
    case five = 5
    case ten = 10
    case fifteen = 15

    var id: Int { rawValue }
    var label: String { "\(rawValue) min" }
    var seconds: TimeInterval { TimeInterval(rawValue * 60) }
}
