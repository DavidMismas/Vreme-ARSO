import SwiftUI

struct WeatherGlyph: View {
    let condition: WidgetWeatherCondition
    let size: CGFloat

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size + 8, height: size + 8)
    }

    private var symbolName: String {
        switch condition {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .heavyRain: return "cloud.heavyrain.fill"
        case .storm: return "cloud.bolt.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .fog: return "cloud.fog.fill"
        case .wind: return "wind"
        case .unknown: return "cloud"
        }
    }

    private var color: Color {
        switch condition {
        case .clear:
            return .yellow
        case .partlyCloudy:
            return .orange
        case .cloudy, .fog, .unknown:
            return .secondary
        case .rain, .heavyRain, .storm:
            return .blue
        case .snow:
            return .cyan
        case .wind:
            return .teal
        }
    }
}
