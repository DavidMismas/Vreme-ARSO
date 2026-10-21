import Foundation

struct SnowStationReading: Identifiable, Equatable {
    let name: String
    let depthCentimeters: Int
    let newSnowCentimeters: Int?
    let updatedAt: Date
    let isAutomatic: Bool

    var id: String { Self.identifier(for: name) }

    static func identifier(for name: String) -> String {
        "snow:" + name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "sl_SI"))
            .lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum SnowObservationHTMLParser {
    static let automaticURL = URL(string: "https://meteo.arso.gov.si/uploads/probase/www/observ/surface/text/sl/observationAms_si-snow_latest.html")!
    static let manualURL = URL(string: "https://meteo.arso.gov.si/uploads/probase/www/observ/surface/text/sl/observation_si-snow_latest.html")!

    static func parse(automaticData: Data?, manualData: Data?, now: Date = .now) -> [SnowStationReading] {
        let automatic = automaticData.map { parseTable($0, automatic: true, now: now) } ?? []
        let manual = manualData.map { parseTable($0, automatic: false, now: now) } ?? []
        // Observed values take precedence when both sources name the same station.
        var byID = Dictionary(uniqueKeysWithValues: automatic.map { ($0.id, $0) })
        for reading in manual { byID[reading.id] = reading }
        return byID.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    private static func parseTable(_ data: Data, automatic: Bool, now: Date) -> [SnowStationReading] {
        guard let html = String(data: data, encoding: .utf8),
              let table = matches("<table[^>]*class=[\"']meteoSI-table[\"'][^>]*>(.*?)</table>", in: html).first,
              let timestamp = matches("(\\d{2}\\.\\d{2}\\.\\d{4}\\s+\\d{2}:\\d{2})", in: table).first,
              let updatedAt = dateFormatter.date(from: timestamp),
              now.timeIntervalSince(updatedAt) >= -3600,
              now.timeIntervalSince(updatedAt) <= 36 * 3600 else { return [] }

        return matches("<tr[^>]*>(.*?)</tr>", in: table).compactMap { row in
            let cells = matches("<t[dh][^>]*>(.*?)</t[dh]>", in: row).map { $0.arsoStrippedHTML() }
            let depthIndex = automatic ? 2 : 3
            let newIndex = automatic ? 3 : 2
            guard cells.count > depthIndex,
                  let depth = centimeters(cells[depthIndex]),
                  depth >= 0,
                  let name = cells.first?.nilIfBlank else { return nil }
            return SnowStationReading(name: name, depthCentimeters: depth,
                                      newSnowCentimeters: cells.indices.contains(newIndex) ? centimeters(cells[newIndex]) : nil,
                                      updatedAt: updatedAt, isAutomatic: automatic)
        }
    }

    private static func centimeters(_ text: String) -> Int? {
        guard let raw = matches("^\\s*(-?\\d+)\\s*cm\\b", in: text).first else { return nil }
        return Int(raw)
    }

    private static func matches(_ pattern: String, in string: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return [] }
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        return regex.matches(in: string, range: range).compactMap { match in
            guard match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: string) else { return nil }
            return String(string[range])
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()
}
