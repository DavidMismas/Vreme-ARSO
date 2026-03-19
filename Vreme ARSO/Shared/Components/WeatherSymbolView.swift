import SwiftUI

struct WeatherSymbolView: View {
    let condition: WeatherCondition
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size, weight: .regular))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(symbolColor)
            .accessibilityHidden(true)
    }

    private var symbolName: String {
        switch condition {
        case .clear:
            return "sun.max"
        case .partlyCloudy:
            return "cloud.sun"
        case .cloudy:
            return "cloud"
        case .rain:
            return "cloud.rain"
        case .heavyRain:
            return "cloud.heavyrain"
        case .storm:
            return "cloud.bolt.rain"
        case .snow:
            return "cloud.snow"
        case .fog:
            return "cloud.fog"
        case .wind:
            return "wind"
        case .unknown:
            return "cloud"
        }
    }

    private var symbolColor: Color {
        switch condition {
        case .clear:
            return .orange
        case .partlyCloudy:
            return .blue
        case .cloudy, .fog, .unknown:
            return .secondary
        case .rain, .heavyRain:
            return .cyan
        case .storm:
            return .indigo
        case .snow:
            return .mint
        case .wind:
            return AppTheme.Colors.accent
        }
    }
}
