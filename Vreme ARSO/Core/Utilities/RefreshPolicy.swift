import Foundation

enum RefreshPolicy {
    case currentConditions
    case forecastText
    case imagery

    var interval: TimeInterval {
        switch self {
        case .currentConditions:
            return 15 * 60
        case .forecastText:
            return 60 * 60
        case .imagery:
            return 5 * 60
        }
    }
}
