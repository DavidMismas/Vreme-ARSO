import Foundation

struct ForecastDay: Identifiable, Hashable, Sendable {
    let id: String
    let date: Date?
    let summary: String
    let minTemperature: Double?
    let maxTemperature: Double?
    let weatherSymbol: String?
    let windDescription: String?
}
