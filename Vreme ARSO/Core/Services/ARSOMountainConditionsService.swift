import Foundation

struct ARSOMountainConditionsService {
    let apiClient: APIClientProtocol

    func fetchReport() async throws -> MountainConditionsReport {
        let data = try await apiClient.data(for: .mountainForecast)
        let locations = try parseLocations(from: data)

        return MountainConditionsReport(
            locations: locations,
            sourceURL: Endpoint.mountainForecast.url
        )
    }

    func parseLocations(from data: Data) throws -> [MountainConditionLocation] {
        guard let html = String(data: data, encoding: .utf8) else {
            throw ARSOError.parsingFailed("Napovedi za gore ni bilo mogoče prebrati.")
        }

        let tables = matches(in: html, pattern: "<table[^>]*class=\"meteoSI-table\"[^>]*>(.*?)</table>")
        let locations = tables.compactMap(parseLocation(from:))

        guard !locations.isEmpty else {
            throw ARSOError.parsingFailed("ARSO trenutno ne objavi razmer v gorah.")
        }

        return locations
    }

    private func parseLocation(from tableHTML: String) -> MountainConditionLocation? {
        let rows = parseRows(from: tableHTML)
        guard let locationName = rows.first?.first?.arsoStrippedHTML().nilIfBlank,
              let headerCells = rows.first(where: { $0.count > 1 }) else {
            return nil
        }

        let labels = Array(headerCells.dropFirst()).map { $0.arsoStrippedHTML() }
        let issuedAtText = headerCells.first?.arsoStrippedHTML().nilIfBlank
        let topElevation = rows.first(where: { ($0.first?.arsoStrippedHTML().localizedCaseInsensitiveContains("na vrhu:")) == true })?.first?.arsoStrippedHTML()
        let bottomElevation = rows.first(where: { ($0.first?.arsoStrippedHTML().localizedCaseInsensitiveContains("spodaj:")) == true })?.first?.arsoStrippedHTML()

        let topWeather = rowValues(matching: "Vreme na vrhu", in: rows).first
        let topWindIndex = rowIndex(matching: "Veter na vrhu", in: rows)
        let topWindSpeed = topWindIndex.flatMap { rows[safe: $0 + 1] }.map { Array($0.dropFirst()) }
        let topTemperature = rowValues(matching: "Temperatura na vrhu", in: rows).first

        let bottomWeather = rowValues(matching: "Vreme spodaj", in: rows).first
        let bottomWindIndex = rowIndex(matching: "Veter spodaj", in: rows)
        let bottomWindSpeed = bottomWindIndex.flatMap { rows[safe: $0 + 1] }.map { Array($0.dropFirst()) }
        let bottomTemperature = rowValues(matching: "Temperatura spodaj", in: rows).first

        let slots = labels.enumerated().map { index, label in
            MountainConditionSlot(
                id: "\(locationName)-\(index)",
                label: label,
                topConditionSymbol: topWeather?[safe: index].flatMap(symbolName(in:)),
                topWindSpeed: topWindSpeed?[safe: index]?.arsoStrippedHTML().nilIfBlank,
                topTemperature: topTemperature?[safe: index]?.arsoStrippedHTML().nilIfBlank,
                bottomConditionSymbol: bottomWeather?[safe: index].flatMap(symbolName(in:)),
                bottomWindSpeed: bottomWindSpeed?[safe: index]?.arsoStrippedHTML().nilIfBlank,
                bottomTemperature: bottomTemperature?[safe: index]?.arsoStrippedHTML().nilIfBlank
            )
        }

        return MountainConditionLocation(
            id: locationName,
            name: locationName,
            issuedAtText: issuedAtText,
            topElevation: topElevation,
            bottomElevation: bottomElevation,
            slots: slots
        )
    }

    private func parseRows(from tableHTML: String) -> [[String]] {
        matches(in: tableHTML, pattern: "<tr>(.*?)</tr>").map { rowHTML in
            matches(in: rowHTML, pattern: "<t[hd][^>]*>(.*?)</t[hd]>")
        }
    }

    private func rowValues(matching label: String, in rows: [[String]]) -> [[String]] {
        rows.compactMap { row in
            guard let key = row.first?.arsoStrippedHTML().replacingOccurrences(of: " ", with: " "),
                  key.localizedCaseInsensitiveContains(label) else {
                return nil
            }
            return Array(row.dropFirst())
        }
    }

    private func rowIndex(matching label: String, in rows: [[String]]) -> Int? {
        rows.firstIndex { row in
            guard let key = row.first?.arsoStrippedHTML().replacingOccurrences(of: " ", with: " ") else {
                return false
            }
            return key.localizedCaseInsensitiveContains(label)
        }
    }

    private func symbolName(in htmlCell: String) -> String? {
        firstMatch(in: htmlCell, pattern: "/([A-Za-z0-9_]+)\\.png")
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        matches(in: text, pattern: pattern).first
    }

    private func matches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }

        return regex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text)).compactMap { result in
            guard result.numberOfRanges >= 2,
                  let range = Range(result.range(at: 1), in: text) else {
                return nil
            }
            return String(text[range])
        }
    }
}
