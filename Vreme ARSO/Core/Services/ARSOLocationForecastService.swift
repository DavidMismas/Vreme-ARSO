import CoreLocation
import Foundation

struct ARSOLocationForecastService {
    let apiClient: APIClientProtocol

    private let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    func fetchDailyForecast(for location: ResolvedForecastLocation) async throws -> LocationDailyForecastReport {
        var candidateNames: [String] = []

        if let coordinate = location.coordinate,
           let nearestName = try? await fetchNearestLocationName(for: coordinate) {
            candidateNames.append(nearestName)
        }

        candidateNames.append(location.displayName)

        if let stationName = location.nearestStation?.name {
            candidateNames.append(stationName)
        }

        let uniqueCandidates = candidateNames.uniqueNonEmptyForecastNames()
        var lastError: Error = ARSOError.noData

        for candidate in uniqueCandidates {
            do {
                let data = try await apiClient.data(for: .locationForecast(locationName: candidate))
                let report = try parseReport(
                    from: data,
                    resolvedLocationName: location.displayName,
                    requestedLocationName: candidate
                )

                if !report.days.isEmpty {
                    return report
                }
            } catch {
                lastError = error
            }
        }

        throw lastError
    }

    func fetchNearestLocationName(for coordinate: CLLocationCoordinate2D) async throws -> String {
        let data = try await apiClient.data(
            for: .nearestForecastLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
        )
        return try parseNearestLocationName(from: data)
    }

    func parseNearestLocationName(from data: Data) throws -> String {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let properties = root["properties"] as? [String: Any],
            let title = (properties["title"] as? String)?.nilIfBlank
        else {
            throw ARSOError.parsingFailed("Imena lokacije za napoved ni bilo mogoče razbrati.")
        }

        return title
    }

    func parseReport(
        from data: Data,
        resolvedLocationName: String?,
        requestedLocationName: String?
    ) throws -> LocationDailyForecastReport {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ARSOError.parsingFailed("Dnevne napovedi ni bilo mogoče prebrati.")
        }

        guard
            let forecast24h = root["forecast24h"] as? [String: Any],
            let features = forecast24h["features"] as? [[String: Any]],
            let feature = features.first,
            let properties = feature["properties"] as? [String: Any],
            let daysPayload = properties["days"] as? [[String: Any]]
        else {
            throw ARSOError.parsingFailed("ARSO dnevne napovedi ni vrnil v pričakovani obliki.")
        }

        let locationName = (properties["title"] as? String)?.nilIfBlank
            ?? requestedLocationName
            ?? resolvedLocationName
            ?? "Izbrana lokacija"

        let days = daysPayload.compactMap(parseDay(from:))
        guard !days.isEmpty else {
            throw ARSOError.parsingFailed("ARSO za izbrano lokacijo trenutno ne vrne dnevne napovedi.")
        }

        return LocationDailyForecastReport(
            locationName: locationName,
            resolvedLocationName: resolvedLocationName,
            days: days,
            sourceURL: Endpoint.locationForecast(locationName: locationName).url
        )
    }

    private func parseDay(from payload: [String: Any]) -> LocationDailyForecastDay? {
        guard
            let dateString = payload["date"] as? String,
            let timeline = payload["timeline"] as? [[String: Any]],
            let summary = timeline.first
        else {
            return nil
        }

        let displaySummary = firstNonEmptyString(
            summary["clouds_shortText_wwsyn_shortText"] as? String,
            summary["wwsyn_shortText"] as? String,
            summary["clouds_shortText"] as? String
        ) ?? "Ni podatka"

        let iconName = firstNonEmptyString(
            summary["wwsyn_icon"] as? String,
            summary["clouds_icon_wwsyn_icon"] as? String
        )

        let windDescription = firstNonEmptyString(
            summary["ff_shortText"] as? String,
            summary["dd_shortText"] as? String
        )

        return LocationDailyForecastDay(
            id: dateString,
            date: apiDateFormatter.date(from: dateString),
            summary: displaySummary,
            minTemperature: Double((summary["tnsyn"] as? String ?? "").replacingOccurrences(of: ",", with: ".")),
            maxTemperature: Double((summary["txsyn"] as? String ?? "").replacingOccurrences(of: ",", with: ".")),
            weatherSymbol: iconName,
            windDescription: windDescription,
            precipitationAmount: Double((summary["tp_24h_acc"] as? String ?? "").replacingOccurrences(of: ",", with: "."))
        )
    }

    private func firstNonEmptyString(_ values: String?...) -> String? {
        values.compactMap { $0?.nilIfBlank }.first
    }
}

private extension Array where Element == String {
    func uniqueNonEmptyForecastNames() -> [String] {
        var seen = Set<String>()

        return compactMap { value in
            let trimmed = value.nilIfBlank?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let trimmed else { return nil }

            let key = trimmed.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "sl_SI"))
            guard seen.insert(key).inserted else { return nil }
            return trimmed
        }
    }
}
