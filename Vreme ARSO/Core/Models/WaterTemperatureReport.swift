import Foundation

struct WaterTemperatureSlot: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let seaTemperature: String
    let seaState: String?
    let windSpeed: String?
}

struct WaterTemperatureReport: Sendable {
    let issuedAtText: String?
    let statusMessage: String?
    let slots: [WaterTemperatureSlot]
    let sourceURL: URL
}
