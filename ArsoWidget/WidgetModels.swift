import Foundation
import SwiftUI

enum WidgetWeatherCondition: String, Codable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case heavyRain
    case storm
    case snow
    case fog
    case wind
    case unknown
}

struct WidgetForecastDay: Identifiable, Codable {
    let id: String
    let weekday: String
    let maxTemperatureText: String
    let minTemperatureText: String
    let condition: WidgetWeatherCondition
}

struct WidgetWarningSummary: Codable {
    let title: String
    let area: String
    let severity: String

    var color: Color {
        switch severity {
        case "extreme":
            return .red
        case "severe":
            return .orange
        case "moderate":
            return .yellow
        case "minor":
            return .blue
        default:
            return .secondary
        }
    }
}

struct WidgetWeatherContent: Codable {
    let locationName: String
    let isFallbackLocation: Bool
    let currentTemperatureText: String
    let currentSummary: String
    let currentCondition: WidgetWeatherCondition
    let dailyForecast: [WidgetForecastDay]
    let primaryWarning: WidgetWarningSummary?
    let forecastSnippetTitle: String?
    let forecastSnippet: String?
    let detailText: String

    func markedAsFallback() -> WidgetWeatherContent {
        WidgetWeatherContent(
            locationName: locationName,
            isFallbackLocation: true,
            currentTemperatureText: currentTemperatureText,
            currentSummary: currentSummary,
            currentCondition: currentCondition,
            dailyForecast: dailyForecast,
            primaryWarning: primaryWarning,
            forecastSnippetTitle: forecastSnippetTitle,
            forecastSnippet: forecastSnippet,
            detailText: detailText
        )
    }

    static let placeholder = WidgetWeatherContent(
        locationName: "Vreme ARSO",
        isFallbackLocation: true,
        currentTemperatureText: "Ni podatka",
        currentSummary: "Zadnji podatki niso na voljo",
        currentCondition: .partlyCloudy,
        dailyForecast: [
            WidgetForecastDay(id: "1", weekday: "Pet", maxTemperatureText: "12°", minTemperatureText: "2°", condition: .partlyCloudy),
            WidgetForecastDay(id: "2", weekday: "Sob", maxTemperatureText: "11°", minTemperatureText: "3°", condition: .cloudy),
            WidgetForecastDay(id: "3", weekday: "Ned", maxTemperatureText: "10°", minTemperatureText: "4°", condition: .rain),
            WidgetForecastDay(id: "4", weekday: "Pon", maxTemperatureText: "13°", minTemperatureText: "5°", condition: .partlyCloudy),
            WidgetForecastDay(id: "5", weekday: "Tor", maxTemperatureText: "15°", minTemperatureText: "6°", condition: .clear),
        ],
        primaryWarning: WidgetWarningSummary(title: "Rumeno opozorilo", area: "Osrednja Slovenija", severity: "moderate"),
        forecastSnippetTitle: "Napoved",
        forecastSnippet: "Danes bo delno do zmerno oblačno, veter bo večinoma šibak.",
        detailText: "Vir podatkov: ARSO."
    )
}
