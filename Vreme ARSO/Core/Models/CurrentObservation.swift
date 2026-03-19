import Foundation

struct CurrentObservation: Identifiable, Hashable, Sendable {
    let stationID: String
    let timestamp: Date?
    let temperature: Double?
    let apparentTemperature: Double?
    let humidity: Int?
    let pressure: Double?
    let windSpeed: Double?
    let windGust: Double?
    let windDirection: String?
    let windDirectionDegrees: Double?
    let precipitation: Double?
    let cloudiness: String?
    let weatherSymbol: String?
    let weatherDescription: String?
    let visibilityKilometers: Double?
    let source: String

    var id: String { stationID }
}
