import Foundation

struct ARSOCurrentWeatherService {
    let apiClient: APIClientProtocol
    let xmlParser: XMLParserService

    func fetchCurrentObservations() async throws -> [CurrentObservation] {
        let data = try await apiClient.data(for: .observationsOverview)
        let root = try xmlParser.parse(data: data)
        return ARSOObservationFeedMapper().map(root: root).observations
    }
}
