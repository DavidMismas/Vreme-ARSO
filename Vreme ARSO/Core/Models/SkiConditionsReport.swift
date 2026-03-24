import Foundation

struct SkiConditionLocation: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let subtitle: String?
    let snowDepthCentimeters: Int?
    let newSnowCentimeters: Int?
    let temperature: Double?
    let weatherDescription: String?
    let weatherSymbol: String?
    let updatedAt: Date?
}

struct SkiConditionsReport: Sendable {
    let issuedAt: Date?
    let locations: [SkiConditionLocation]
    let sourceURL: URL
}
