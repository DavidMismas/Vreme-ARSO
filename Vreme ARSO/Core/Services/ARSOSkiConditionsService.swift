import Foundation

struct ARSOSkiConditionsService {
    let apiClient: APIClientProtocol
    let xmlParser: XMLParserService

    func fetchReport(now: Date = .now) async throws -> SkiConditionsReport {
        async let automatic = try? apiClient.data(for: .snowAutomaticObservations)
        async let manual = try? apiClient.data(for: .snowManualObservations)
        let (automaticData, manualData) = await (automatic, manual)
        guard automaticData != nil || manualData != nil else {
            throw ARSOError.noData
        }
        let readings = SnowObservationHTMLParser.parse(automaticData: automaticData, manualData: manualData, now: now)
        let locations = readings.map { reading in
            SkiConditionLocation(
                id: reading.id,
                name: reading.name,
                subtitle: reading.isAutomatic ? "Samodejna ARSO postaja" : "Opazovalna ARSO postaja",
                snowDepthCentimeters: reading.depthCentimeters,
                newSnowCentimeters: reading.newSnowCentimeters,
                temperature: nil,
                weatherDescription: nil,
                weatherSymbol: nil,
                updatedAt: reading.updatedAt
            )
        }
        return SkiConditionsReport(
            issuedAt: readings.map(\.updatedAt).max(),
            locations: locations,
            sourceURL: SnowObservationHTMLParser.automaticURL
        )
    }
}
