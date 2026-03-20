import Foundation
import MapKit

struct ManualLocationResult: Sendable {
    let name: String
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct LocationPreferenceSnapshot {
    let pinnedStationID: String?
    let useCurrentLocation: Bool
    let selectedStationID: String?
    let manualLocationName: String?
    let manualCoordinate: CLLocationCoordinate2D?
}

final class LocationResolver {
    private let forecastProvider: ForecastLocationProvider
    private let geocodingLocale = Locale(identifier: "sl_SI")

    init(forecastProvider: ForecastLocationProvider) {
        self.forecastProvider = forecastProvider
    }

    func resolve(
        preference: LocationPreferenceSnapshot,
        currentLocation: CLLocation?,
        stations: [WeatherStation],
        observations: [CurrentObservation]
    ) async -> ResolvedForecastLocation? {
        let observationsByStation = Dictionary(uniqueKeysWithValues: observations.map { ($0.stationID, $0) })

        if let pinnedStationID = preference.pinnedStationID,
           let station = stations.first(where: { $0.id == pinnedStationID }) {
            return ResolvedForecastLocation(
                displayName: station.name,
                detailText: "Prikaz po izbrani priljubljeni postaji",
                source: .station,
                coordinate: station.coordinate,
                nearestStation: station,
                observation: observationsByStation[station.id]
            )
        }

        if preference.useCurrentLocation,
           let currentLocation {
            let coordinate = currentLocation.coordinate
            let nearestStation = forecastProvider.nearestStation(to: coordinate, in: stations)
            let placeName = await reverseGeocodeName(for: coordinate) ?? nearestStation?.name ?? "Trenutna lokacija"

            return ResolvedForecastLocation(
                displayName: placeName,
                detailText: nearestStation.map { "Najbližja postaja: \($0.name)" },
                source: .currentLocation,
                coordinate: coordinate,
                nearestStation: nearestStation,
                observation: nearestStation.flatMap { observationsByStation[$0.id] }
            )
        }

        if let manualCoordinate = preference.manualCoordinate {
            let nearestStation = forecastProvider.nearestStation(to: manualCoordinate, in: stations)
            return ResolvedForecastLocation(
                displayName: preference.manualLocationName ?? nearestStation?.name ?? "Izbrani kraj",
                detailText: nearestStation.map { "Najbližja postaja: \($0.name)" },
                source: .manualPlace,
                coordinate: manualCoordinate,
                nearestStation: nearestStation,
                observation: nearestStation.flatMap { observationsByStation[$0.id] }
            )
        }

        if let selectedStationID = preference.selectedStationID,
           let station = stations.first(where: { $0.id == selectedStationID }) {
            return ResolvedForecastLocation(
                displayName: station.name,
                detailText: "Prikaz po izbrani postaji",
                source: .station,
                coordinate: station.coordinate,
                nearestStation: station,
                observation: observationsByStation[station.id]
            )
        }

        guard let fallbackStation = stations.first(where: { $0.id == "LJUBL-ANA_BEZIGRAD_" }) ?? stations.first else {
            return nil
        }

        return ResolvedForecastLocation(
            displayName: fallbackStation.name,
            detailText: "Prikaz po referenčni postaji",
            source: .station,
            coordinate: fallbackStation.coordinate,
            nearestStation: fallbackStation,
            observation: observationsByStation[fallbackStation.id]
        )
    }

    func geocode(place query: String) async throws -> ManualLocationResult {
        guard let request = MKGeocodingRequest(addressString: query) else {
            throw ARSOError.parsingFailed("Kraja ni bilo mogoče najti.")
        }
        request.preferredLocale = geocodingLocale
        let mapItems = try await request.mapItems

        guard let mapItem = mapItems.first else {
            throw ARSOError.parsingFailed("Kraja ni bilo mogoče najti.")
        }
        let location = mapItem.location

        let candidates: [String?] = [
            mapItem.addressRepresentations?.cityName,
            mapItem.addressRepresentations?.cityWithContext,
            mapItem.name,
            mapItem.address?.shortAddress,
            mapItem.address?.fullAddress
        ]
        let locality = candidates
            .compactMap { $0?.nilIfBlank }
            .first ?? query

        return ManualLocationResult(
            name: locality,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    func reverseGeocodeName(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return nil
        }
        request.preferredLocale = geocodingLocale

        do {
            let mapItems = try await request.mapItems
            guard let mapItem = mapItems.first else {
                return nil
            }

            let candidates: [String?] = [
                mapItem.addressRepresentations?.cityName,
                mapItem.addressRepresentations?.cityWithContext,
                mapItem.name,
                mapItem.address?.shortAddress,
                mapItem.address?.fullAddress
            ]
            return candidates
                .compactMap { $0?.nilIfBlank }
                .first
        } catch {
            return nil
        }
    }
}
