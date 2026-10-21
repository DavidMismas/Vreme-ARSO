import SwiftUI

/// Four visual families; unsupported observations retain a calm, cloudy sky.
enum WeatherAtmosphere: Equatable {
    case sunny, cloudy, rainy, snowy

    init(_ condition: WeatherCondition) {
        switch condition {
        case .clear, .partlyCloudy: self = .sunny
        case .rain, .heavyRain, .storm: self = .rainy
        case .snow: self = .snowy
        default: self = .cloudy
        }
    }

    var colors: [Color] {
        switch self {
        case .sunny: return [Color(red: 0.08, green: 0.31, blue: 0.51), Color(red: 0.20, green: 0.40, blue: 0.51), Color(red: 0.07, green: 0.14, blue: 0.23)]
        case .cloudy: return [Color(red: 0.22, green: 0.30, blue: 0.39), Color(red: 0.14, green: 0.22, blue: 0.31), Color(red: 0.06, green: 0.12, blue: 0.19)]
        case .rainy: return [Color(red: 0.10, green: 0.19, blue: 0.31), Color(red: 0.14, green: 0.26, blue: 0.35), Color(red: 0.04, green: 0.09, blue: 0.17)]
        case .snowy: return [Color(red: 0.29, green: 0.39, blue: 0.50), Color(red: 0.19, green: 0.30, blue: 0.41), Color(red: 0.09, green: 0.16, blue: 0.25)]
        }
    }
}

private struct WeatherAtmosphereKey: EnvironmentKey {
    static let defaultValue: WeatherAtmosphere = .cloudy
}

extension EnvironmentValues {
    var weatherAtmosphere: WeatherAtmosphere {
        get { self[WeatherAtmosphereKey.self] }
        set { self[WeatherAtmosphereKey.self] = newValue }
    }
}

struct WeatherAtmospherePreference: PreferenceKey {
    static let defaultValue: WeatherAtmosphere? = nil
    static func reduce(value: inout WeatherAtmosphere?, nextValue: () -> WeatherAtmosphere?) {
        value = nextValue() ?? value
    }
}

struct WeatherBackground: View {
    @Environment(\.weatherAtmosphere) private var atmosphere
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: reduceMotion || scenePhase != .active)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geometry in
                ZStack {
                    LinearGradient(colors: atmosphere.colors, startPoint: .top, endPoint: .bottom)
                    if atmosphere == .sunny {
                        Circle()
                            .fill(RadialGradient(colors: [.yellow.opacity(0.65), .orange.opacity(0.16), .clear], center: .center, startRadius: 15, endRadius: 180))
                            .frame(width: 360, height: 360)
                            .scaleEffect(1 + sin(time / 8) * 0.04)
                            .position(x: geometry.size.width * 0.85, y: 70)
                    }
                    Canvas { context, size in
                        // Deterministic positions prevent particles jumping between redraws.
                        for index in 0..<7 {
                            let seed = Double(index)
                            let drift = sin(time / 30 + seed) * 45
                            let rect = CGRect(x: seed * 93 - 180 + drift, y: seed * 73 - 80, width: 340, height: 120)
                            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(atmosphere == .sunny ? 0.025 : 0.055)))
                        }
                        guard atmosphere == .rainy || atmosphere == .snowy else { return }
                        let snow = atmosphere == .snowy
                        for index in 0..<(snow ? 65 : 90) {
                            let seed = Double(index)
                            let speed = snow ? 24.0 : 210.0
                            let height = size.height + 40
                            let y = (seed * 97 + time * speed).truncatingRemainder(dividingBy: height) - 20
                            let x = (seed * 137 + (snow ? sin(time / 4 + seed) * 18 : -y * 0.18)).truncatingRemainder(dividingBy: size.width + 40)
                            if snow {
                                let radius = 1.5 + Double(index % 3)
                                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)), with: .color(.white.opacity(0.38)))
                            } else {
                                var drop = Path()
                                drop.move(to: CGPoint(x: x, y: y))
                                drop.addLine(to: CGPoint(x: x - 3, y: y + 17))
                                context.stroke(drop, with: .color(.white.opacity(0.18)), lineWidth: 1)
                            }
                        }
                    }
                    LinearGradient(colors: [.clear, .black.opacity(0.18)], startPoint: .top, endPoint: .bottom)
                }
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview("Dež") {
    WeatherBackground().environment(\.weatherAtmosphere, .rainy)
}

#Preview("Sončno") {
    WeatherBackground().environment(\.weatherAtmosphere, .sunny)
}

#Preview("Oblačno") {
    WeatherBackground().environment(\.weatherAtmosphere, .cloudy)
}

#Preview("Sneg") {
    WeatherBackground().environment(\.weatherAtmosphere, .snowy)
}
