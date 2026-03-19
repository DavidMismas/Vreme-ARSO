import Foundation

struct MountainConditionSlot: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let topConditionSymbol: String?
    let topWindSpeed: String?
    let topTemperature: String?
    let bottomConditionSymbol: String?
    let bottomWindSpeed: String?
    let bottomTemperature: String?
}

struct MountainConditionLocation: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let issuedAtText: String?
    let topElevation: String?
    let bottomElevation: String?
    let slots: [MountainConditionSlot]
}

struct MountainConditionsReport: Sendable {
    let locations: [MountainConditionLocation]
    let sourceURL: URL
}
