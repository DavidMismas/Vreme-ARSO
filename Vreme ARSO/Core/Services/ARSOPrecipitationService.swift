import CoreLocation
import Foundation

struct ARSOPrecipitationService {
    let apiClient: APIClientProtocol

    func stations(now: Date = .now) async throws -> [PrecipitationStationStatus] {
        let data = try await apiClient.data(for: .automaticObservations)
        return try ARSOPrecipitationParser.parseStations(data: data, now: now)
    }

    func reading(near location: ResolvedForecastLocation, now: Date = .now) async throws -> PrecipitationReading? {
        let data = try await apiClient.data(for: .automaticObservations)
        let stations = try ARSOPrecipitationParser.parse(data: data, now: now)
        if let stationID = location.nearestStation?.id,
           let matching = stations.first(where: { $0.reading.stationID == stationID }) {
            return matching.reading
        }
        guard let coordinate = location.coordinate ?? location.nearestStation?.coordinate else { return nil }
        let place = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let closest = stations.min {
            CLLocation(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude).distance(from: place)
            < CLLocation(latitude: $1.coordinate.latitude, longitude: $1.coordinate.longitude).distance(from: place)
        }
        guard let closest,
              CLLocation(latitude: closest.coordinate.latitude, longitude: closest.coordinate.longitude).distance(from: place) <= 35_000
        else { return nil }
        return closest.reading
    }
}
