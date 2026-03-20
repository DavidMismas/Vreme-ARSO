import Foundation

struct LocationDailyForecastDay: Identifiable, Hashable, Sendable {
    let id: String
    let date: Date?
    let summary: String
    let minTemperature: Double?
    let maxTemperature: Double?
    let weatherSymbol: String?
    let windDescription: String?
    let precipitationAmount: Double?
}

struct LocationDailyForecastReport: Sendable {
    let locationName: String
    let resolvedLocationName: String?
    let days: [LocationDailyForecastDay]
    let sourceURL: URL
}
