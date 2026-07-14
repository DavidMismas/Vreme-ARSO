import Foundation

actor ARSOAirQualityService {
    private let apiClient: APIClientProtocol
    private var snapshotCache: AirQualitySnapshot?
    private var historicalCacheByStation: [String: [AirQualityMeasurement]]?
    private var historicalCacheFetchedAt: Date?
    private let historicalCacheMaxAge: TimeInterval = 15 * 60

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func cachedSnapshot() -> AirQualitySnapshot? {
        snapshotCache
    }

    func fetchLatestSnapshot(forceRefresh: Bool = false) async throws -> AirQualitySnapshot {
        if !forceRefresh, let snapshotCache {
            return snapshotCache
        }

        async let hourlyData = apiClient.data(for: .airQualityHourlyLatest)
        async let stationData = apiClient.data(for: .airQualityDailyLatest)
        let (hourlyXML, stationsXML) = try await (hourlyData, stationData)

        async let measurements = parseMeasurements(from: hourlyXML)
        async let stationsFromDaily = parseStations(from: stationsXML)
        async let stationsFromHourly = parseStations(from: hourlyXML)

        let parsedMeasurements = try await measurements
        let dailyStations = try await stationsFromDaily
        let hourlyStations = try await stationsFromHourly

        let mergedStations = mergeStations(primary: dailyStations, secondary: hourlyStations)
        let measurementsByStationCode = Dictionary(uniqueKeysWithValues: parsedMeasurements.map { ($0.stationCode, $0) })
        let snapshot = AirQualitySnapshot(
            stations: mergedStations,
            measurementsByStationCode: measurementsByStationCode,
            fetchedAt: Date()
        )

        snapshotCache = snapshot
        return snapshot
    }

    func fetchHistoricalMeasurements(for stationCode: String, forceRefresh: Bool = false) async throws -> [AirQualityMeasurement] {
        let normalizedCode = stationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedCode.isEmpty else {
            return []
        }

        if !forceRefresh, let cachedMeasurements = cachedHistoricalMeasurements(for: normalizedCode) {
            return cachedMeasurements
        }

        do {
            let xmlData = try await apiClient.data(for: .airQualityHourlySevenDays)
            let parsed = try await parseMeasurements(from: xmlData)
            let groupedByStation = groupHistoricalMeasurements(parsed)
            historicalCacheByStation = groupedByStation
            historicalCacheFetchedAt = Date()
            return groupedByStation[normalizedCode] ?? []
        } catch {
            if let fallback = historicalCacheByStation?[normalizedCode] {
                return fallback
            }
            throw error
        }
    }

    private func parseMeasurements(from data: Data) async throws -> [AirQualityMeasurement] {
        try await Task.detached(priority: .utility) {
            let parser = AirQualityMeasurementsXMLParser()
            return try parser.parse(data: data)
        }.value
    }

    private func parseStations(from data: Data) async throws -> [AirQualityStation] {
        try await Task.detached(priority: .utility) {
            let parser = AirQualityStationsXMLParser()
            return try parser.parse(data: data)
        }.value
    }

    private func mergeStations(primary: [AirQualityStation], secondary: [AirQualityStation]) -> [AirQualityStation] {
        var byCode = Dictionary(uniqueKeysWithValues: primary.map { ($0.code, $0) })

        for station in secondary where byCode[station.code] == nil {
            byCode[station.code] = station
        }

        return byCode.values.sorted { lhs, rhs in
            lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private func cachedHistoricalMeasurements(for stationCode: String) -> [AirQualityMeasurement]? {
        guard let fetchedAt = historicalCacheFetchedAt,
              let historicalCacheByStation,
              Date().timeIntervalSince(fetchedAt) <= historicalCacheMaxAge else {
            return nil
        }

        return historicalCacheByStation[stationCode] ?? []
    }

    private func groupHistoricalMeasurements(_ measurements: [AirQualityMeasurement]) -> [String: [AirQualityMeasurement]] {
        let grouped = Dictionary(grouping: measurements, by: \.stationCode)

        return grouped.mapValues { stationMeasurements in
            let deduplicated = deduplicateByTimestamp(stationMeasurements)
            return deduplicated.sorted { lhs, rhs in
                (lhs.lastUpdate ?? .distantPast) < (rhs.lastUpdate ?? .distantPast)
            }
        }
    }

    private func deduplicateByTimestamp(_ measurements: [AirQualityMeasurement]) -> [AirQualityMeasurement] {
        var byTimestamp: [Date: AirQualityMeasurement] = [:]
        var undatedMeasurements: [AirQualityMeasurement] = []

        for measurement in measurements {
            guard let timestamp = measurement.lastUpdate else {
                undatedMeasurements.append(measurement)
                continue
            }

            if let existing = byTimestamp[timestamp] {
                if existing.pm25 == nil, measurement.pm25 != nil {
                    byTimestamp[timestamp] = measurement
                }
            } else {
                byTimestamp[timestamp] = measurement
            }
        }

        return Array(byTimestamp.values) + undatedMeasurements
    }
}
