import Foundation

struct ARSOStationsService {
    let apiClient: APIClientProtocol
    let xmlParser: XMLParserService

    func fetchStations() async throws -> [WeatherStation] {
        let data = try await apiClient.data(for: .observationsOverview)
        let root = try xmlParser.parse(data: data)
        return ARSOObservationFeedMapper().map(root: root).stations
    }
}
