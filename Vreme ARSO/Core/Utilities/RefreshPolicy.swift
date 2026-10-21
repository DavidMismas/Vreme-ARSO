import Foundation

enum RefreshPolicy {
    case currentConditions
    case forecastText
    case imagery

    var interval: TimeInterval {
        switch self {
        case .currentConditions:
            return 60
        case .forecastText:
            return 30 * 60
        case .imagery:
            return 3 * 60
        }
    }
}


enum AutoRefreshInterval: Int, CaseIterable, Identifiable {
    case hourly = 1
    case everyThreeHours = 3
    case everySixHours = 6

    var id: Int { rawValue }
    var seconds: TimeInterval { TimeInterval(rawValue * 60 * 60) }
    var title: String {
        switch self {
        case .hourly: return "Vsako uro"
        case .everyThreeHours: return "Na 3 ure"
        case .everySixHours: return "Na 6 ur"
        }
    }

    func isDue(lastUpdate: Date?, now: Date = .now) -> Bool {
        guard let lastUpdate else { return true }
        return now.timeIntervalSince(lastUpdate) >= seconds
    }
}
