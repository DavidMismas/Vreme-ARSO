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
