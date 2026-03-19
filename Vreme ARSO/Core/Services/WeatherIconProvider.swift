import Foundation

struct WeatherIconProvider {
    func condition(for observation: CurrentObservation?) -> WeatherCondition {
        guard let observation else { return .unknown }
        return condition(
            symbolName: observation.weatherSymbol,
            description: observation.weatherDescription
        )
    }

    func condition(forSymbol symbolName: String?, description: String? = nil) -> WeatherCondition {
        condition(symbolName: symbolName, description: description)
    }

    private func condition(symbolName: String?, description: String?) -> WeatherCondition {
        let icon = symbolName?.lowercased() ?? ""
        let description = description?.lowercased() ?? ""

        if icon.contains("ts") || description.contains("neviht") {
            return .storm
        }

        if icon.contains("sn") || description.contains("sneg") || description.contains("snež") {
            return .snow
        }

        if icon.contains("fg") || description.contains("megla") || description.contains("megleno") {
            return .fog
        }

        if icon.contains("shra") || icon.contains("ra") || description.contains("dež") || description.contains("ploha") {
            if description.contains("močan") || description.contains("naliv") {
                return .heavyRain
            }
            return .rain
        }

        if description.contains("vetrov") || description.contains("veter") {
            return .wind
        }

        if icon == "clear" || description.contains("jasno") {
            return .clear
        }

        if icon.contains("mostclear") || icon.contains("modcloudy") || icon.contains("partcloudy") || description.contains("delno oblačno") || description.contains("zmerno oblačno") {
            return .partlyCloudy
        }

        if icon.contains("prevcloudy") || icon.contains("overcast") || description.contains("pretežno oblačno") || description.contains("oblačno") {
            return .cloudy
        }

        return .unknown
    }
}
