import CoreLocation
import Foundation

struct WidgetWeatherLoader {
    private let session: URLSession = .shared

    func loadContent() async -> WidgetWeatherContent {
        do {
            let preference = readPreferredLocation()
            let resolved = try await resolveLocation(preference: preference)
            let forecastPayload = try await fetchJSON(from: resolved.forecastURL)
            let nonlocationPayload = try? await fetchJSON(from: URL(string: "https://vreme.arso.gov.si/api/1.0/nonlocation/?lang=sl")!)
            return try parseContent(
                forecastPayload: forecastPayload,
                nonlocationPayload: nonlocationPayload,
                preferredDisplayName: resolved.displayName,
                fallbackLocation: resolved.isFallback
            )
        } catch {
            return .placeholder
        }
    }

    private func readPreferredLocation() -> WidgetLocationPreference {
        let defaults = WidgetSharedStore.defaults

        let useCurrentLocation = defaults?.object(forKey: WidgetSharedStore.Keys.useCurrentLocation) as? Bool ?? true
        let manualLocationName = defaults?.string(forKey: WidgetSharedStore.Keys.manualLocationName)
        let manualLatitude = defaults?.object(forKey: WidgetSharedStore.Keys.manualLocationLatitude) as? Double
        let manualLongitude = defaults?.object(forKey: WidgetSharedStore.Keys.manualLocationLongitude) as? Double
        let currentLatitude = defaults?.object(forKey: WidgetSharedStore.Keys.currentLocationLatitude) as? Double
        let currentLongitude = defaults?.object(forKey: WidgetSharedStore.Keys.currentLocationLongitude) as? Double
        let useSelectedFavoriteStation = defaults?.object(forKey: WidgetSharedStore.Keys.useSelectedFavoriteStation) as? Bool ?? false
        let selectedStationName = defaults?.string(forKey: WidgetSharedStore.Keys.selectedStationName)
        let selectedStationLatitude = defaults?.object(forKey: WidgetSharedStore.Keys.selectedStationLatitude) as? Double
        let selectedStationLongitude = defaults?.object(forKey: WidgetSharedStore.Keys.selectedStationLongitude) as? Double

        return WidgetLocationPreference(
            useSelectedFavoriteStation: useSelectedFavoriteStation,
            selectedStationName: selectedStationName,
            selectedStationCoordinate: coordinate(latitude: selectedStationLatitude, longitude: selectedStationLongitude),
            useCurrentLocation: useCurrentLocation,
            manualLocationName: manualLocationName,
            manualCoordinate: coordinate(latitude: manualLatitude, longitude: manualLongitude),
            currentCoordinate: coordinate(latitude: currentLatitude, longitude: currentLongitude)
        )
    }

    private func resolveLocation(preference: WidgetLocationPreference) async throws -> WidgetResolvedLocation {
        if preference.useSelectedFavoriteStation {
            if let selectedStationCoordinate = preference.selectedStationCoordinate {
                let nearestName = try await fetchNearestLocationName(for: selectedStationCoordinate)
                return WidgetResolvedLocation(
                    forecastURL: locationURL(named: nearestName),
                    displayName: preference.selectedStationName ?? nearestName,
                    isFallback: false
                )
            }

            if let selectedStationName = preference.selectedStationName?.nilIfBlank {
                return WidgetResolvedLocation(
                    forecastURL: locationURL(named: selectedStationName),
                    displayName: selectedStationName,
                    isFallback: false
                )
            }
        }

        if preference.useCurrentLocation, let currentCoordinate = preference.currentCoordinate {
            let nearestName = try await fetchNearestLocationName(for: currentCoordinate)
            return WidgetResolvedLocation(
                forecastURL: locationURL(named: nearestName),
                displayName: nil,
                isFallback: false
            )
        }

        if let manualLocationName = preference.manualLocationName?.nilIfBlank {
            return WidgetResolvedLocation(
                forecastURL: locationURL(named: manualLocationName),
                displayName: manualLocationName,
                isFallback: false
            )
        }

        if let manualCoordinate = preference.manualCoordinate {
            let nearestName = try await fetchNearestLocationName(for: manualCoordinate)
            return WidgetResolvedLocation(
                forecastURL: locationURL(named: nearestName),
                displayName: nil,
                isFallback: false
            )
        }

        return WidgetResolvedLocation(
            forecastURL: locationURL(named: "Ljubljana"),
            displayName: "Ljubljana",
            isFallback: true
        )
    }

    private func fetchNearestLocationName(for coordinate: CLLocationCoordinate2D) async throws -> String {
        var components = URLComponents(string: "https://vreme.arso.gov.si/api/1.0/locations/")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(coordinate.longitude)),
        ]
        let payload = try await fetchJSON(from: components.url!)

        guard
            let properties = payload["properties"] as? [String: Any],
            let title = (properties["title"] as? String)?.nilIfBlank
        else {
            throw WidgetLoaderError.invalidPayload
        }

        return title
    }

    private func locationURL(named locationName: String) -> URL {
        var components = URLComponents(string: "https://vreme.arso.gov.si/api/1.0/location/")!
        components.queryItems = [
            URLQueryItem(name: "lang", value: "sl"),
            URLQueryItem(name: "location", value: locationName),
        ]
        return components.url!
    }

    private func fetchJSON(from url: URL) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.setValue("VremeARSOWidget/1.0 (iOS WidgetKit)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw WidgetLoaderError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw WidgetLoaderError.invalidPayload
        }

        return json
    }

    private func parseContent(
        forecastPayload: [String: Any],
        nonlocationPayload: [String: Any]?,
        preferredDisplayName: String?,
        fallbackLocation: Bool
    ) throws -> WidgetWeatherContent {
        guard
            let forecast24h = forecastPayload["forecast24h"] as? [String: Any],
            let forecastFeatures = forecast24h["features"] as? [[String: Any]],
            let forecastFeature = forecastFeatures.first,
            let forecastProperties = forecastFeature["properties"] as? [String: Any],
            let daysPayload = forecastProperties["days"] as? [[String: Any]],
            let observation = forecastPayload["observation"] as? [String: Any],
            let observationFeatures = observation["features"] as? [[String: Any]],
            let observationFeature = observationFeatures.first,
            let observationProperties = observationFeature["properties"] as? [String: Any],
            let observationDays = observationProperties["days"] as? [[String: Any]],
            let observationTimeline = observationDays.first?["timeline"] as? [[String: Any]],
            let current = observationTimeline.first
        else {
            throw WidgetLoaderError.invalidPayload
        }

        let locationName = preferredDisplayName?.nilIfBlank
            ?? (forecastProperties["title"] as? String)?.nilIfBlank
            ?? "Ljubljana"
        let currentTemperature = stringValue(current["t"]) ?? "Ni podatka"
        let currentSummary = firstNonEmpty(
            stringValue(current["clouds_shortText_wwsyn_shortText"]),
            stringValue(current["wwsyn_shortText"]),
            stringValue(current["clouds_shortText"])
        ) ?? "Brez opisa"
        let currentIcon = firstNonEmpty(
            stringValue(current["wwsyn_icon"]),
            stringValue(current["clouds_icon_wwsyn_icon"])
        )

        let dailyForecast = daysPayload.prefix(5).compactMap(parseDay)
        let primaryWarning = parsePrimaryWarning(from: nonlocationPayload)
        let forecastSnippet = parseForecastSnippet(from: nonlocationPayload)
        let detailText = buildDetailText(current: current, warning: primaryWarning)

        return WidgetWeatherContent(
            locationName: locationName,
            isFallbackLocation: fallbackLocation,
            currentTemperatureText: "\(currentTemperature) °C",
            currentSummary: currentSummary.capitalizedSentence,
            currentCondition: mapCondition(icon: currentIcon, description: currentSummary),
            dailyForecast: dailyForecast,
            primaryWarning: primaryWarning,
            forecastSnippetTitle: forecastSnippet?.title,
            forecastSnippet: forecastSnippet?.body,
            detailText: detailText
        )
    }

    private func parseDay(from payload: [String: Any]) -> WidgetForecastDay? {
        guard
            let dateString = payload["date"] as? String,
            let timeline = payload["timeline"] as? [[String: Any]],
            let summary = timeline.first
        else {
            return nil
        }

        let date = ISO8601DateFormatter.dayOnly.date(from: dateString)
        let weekday = date.map { WidgetDateFormatters.weekday.string(from: $0) } ?? "Dan"
        let icon = firstNonEmpty(
            stringValue(summary["wwsyn_icon"]),
            stringValue(summary["clouds_icon_wwsyn_icon"])
        )
        let description = firstNonEmpty(
            stringValue(summary["clouds_shortText_wwsyn_shortText"]),
            stringValue(summary["wwsyn_shortText"]),
            stringValue(summary["clouds_shortText"])
        )

        return WidgetForecastDay(
            id: dateString,
            weekday: weekday.capitalizedSentence,
            maxTemperatureText: compactTemperature(stringValue(summary["txsyn"])),
            minTemperatureText: compactTemperature(stringValue(summary["tnsyn"])),
            condition: mapCondition(icon: icon, description: description)
        )
    }

    private func parsePrimaryWarning(from payload: [String: Any]?) -> WidgetWarningSummary? {
        guard
            let warning = payload?["warning_si"] as? [String: Any],
            let locations = warning["locations"] as? [[String: Any]]
        else {
            return nil
        }

        let candidates = locations.compactMap { location -> WidgetWarningSummary? in
            guard
                let summaries = location["summary"] as? [[String: Any]],
                let strongest = summaries.first(where: { !(stringValue($0["event"])?.isEmpty ?? true) }),
                let event = stringValue(strongest["event"])?.nilIfBlank
            else {
                return nil
            }

            return WidgetWarningSummary(
                title: event,
                area: (location["name"] as? String) ?? "Slovenija",
                severity: stringValue(strongest["type"]) == "maxDegreeEvent"
                    ? degreeToSeverity(event)
                    : "moderate"
            )
        }

        return candidates.first
    }

    private func parseForecastSnippet(from payload: [String: Any]?) -> (title: String, body: String)? {
        guard
            let forecastText = payload?["fcast_si_text"] as? [String: Any],
            let sections = forecastText["section"] as? [[String: Any]]
        else {
            return nil
        }

        let preferred = sections.first { section in
            let title = (section["title"] as? String ?? "").uppercased()
            let body = (section["para"] as? String ?? "").nilIfBlank
            return body != nil && title.contains("NAPOVED ZA SLOVENIJO")
        }

        let fallback = sections.first { section in
            (section["para"] as? String)?.nilIfBlank != nil
        }

        guard let section = preferred ?? fallback,
              let body = (section["para"] as? String)?.nilIfBlank else {
            return nil
        }

        let title = (section["title"] as? String)?.nilIfBlank ?? "Napoved"
        return (title.capitalizedSentence, body)
    }

    private func buildDetailText(current: [String: Any], warning: WidgetWarningSummary?) -> String {
        var parts: [String] = []

        if let wind = stringValue(current["ff_shortText"])?.nilIfBlank {
            parts.append("Veter \(wind)")
        }

        if let pressure = stringValue(current["msl"])?.nilIfBlank {
            parts.append("Tlak \(pressure) hPa")
        }

        if warning != nil {
            parts.append("Preveri opozorila ARSO")
        } else {
            parts.append("Vir podatkov: ARSO")
        }

        return parts.joined(separator: " • ")
    }

    private func degreeToSeverity(_ event: String) -> String {
        let lowered = event.lowercased()
        if lowered.contains("rdeče") { return "severe" }
        if lowered.contains("oranžno") { return "moderate" }
        if lowered.contains("rumeno") { return "minor" }
        return "moderate"
    }

    private func compactTemperature(_ value: String?) -> String {
        guard let value = value?.nilIfBlank else { return "–" }
        return "\(value)°"
    }

    private func stringValue(_ any: Any?) -> String? {
        any as? String
    }

    private func firstNonEmpty(_ values: String?...) -> String? {
        values.compactMap { $0?.nilIfBlank }.first
    }

    private func coordinate(latitude: Double?, longitude: Double?) -> CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func mapCondition(icon: String?, description: String?) -> WidgetWeatherCondition {
        let icon = icon?.lowercased() ?? ""
        let description = description?.lowercased() ?? ""

        if icon.contains("ts") || description.contains("neviht") { return .storm }
        if icon.contains("sn") || description.contains("sneg") || description.contains("snež") { return .snow }
        if icon.contains("fg") || description.contains("megla") { return .fog }
        if icon.contains("shra") || icon.contains("lightra") || icon.contains("heavyra") || icon.contains("ra") || description.contains("dež") || description.contains("ploha") {
            if icon.contains("heavy") || description.contains("močan") || description.contains("naliv") {
                return .heavyRain
            }
            return .rain
        }
        if description.contains("veter") { return .wind }
        if icon == "clear" || icon.contains("clear_") || description.contains("jasno") { return .clear }
        if icon.contains("partcloudy") || icon.contains("modcloudy") || description.contains("delno oblačno") || description.contains("zmerno oblačno") { return .partlyCloudy }
        if icon.contains("prevcloudy") || icon.contains("overcast") || description.contains("pretežno oblačno") || description.contains("oblačno") { return .cloudy }
        return .unknown
    }
}

private struct WidgetLocationPreference {
    let useSelectedFavoriteStation: Bool
    let selectedStationName: String?
    let selectedStationCoordinate: CLLocationCoordinate2D?
    let useCurrentLocation: Bool
    let manualLocationName: String?
    let manualCoordinate: CLLocationCoordinate2D?
    let currentCoordinate: CLLocationCoordinate2D?
}

private struct WidgetResolvedLocation {
    let forecastURL: URL
    let displayName: String?
    let isFallback: Bool
}

private enum WidgetLoaderError: Error {
    case invalidResponse
    case invalidPayload
}

private enum WidgetDateFormatters {
    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "EEE"
        return formatter
    }()
}

private extension ISO8601DateFormatter {
    static let dayOnly: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        return formatter
    }()
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var capitalizedSentence: String {
        prefix(1).uppercased() + dropFirst()
    }
}
