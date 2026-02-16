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

/// Weekday options for the billing week reset (Apple weekday numbering: 1=Sun..7=Sat)
enum ResetDay: Int, CaseIterable, Identifiable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4
    case thursday = 5, friday = 6, saturday = 7

    var id: Int { rawValue }
    var label: String {
        switch self {
        case .sunday: "Sun"
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        }
    }
}
