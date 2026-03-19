import Foundation

enum WarningSeverity: String, Codable, Comparable, Sendable {
    case minor
    case moderate
    case severe
    case extreme
    case unknown

    var naslov: String {
        switch self {
        case .minor: return "Nizka"
        case .moderate: return "Srednja"
        case .severe: return "Visoka"
        case .extreme: return "Zelo visoka"
        case .unknown: return "Neznana"
        }
    }

    static func < (lhs: WarningSeverity, rhs: WarningSeverity) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
        case .unknown: return 0
        case .minor: return 1
        case .moderate: return 2
        case .severe: return 3
        case .extreme: return 4
        }
    }
}

struct WarningItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let severity: WarningSeverity
    let area: String
    let validFrom: Date?
    let validTo: Date?
    let body: String
    let eventType: String
    let polygons: [[CoordinatePoint]]
}
