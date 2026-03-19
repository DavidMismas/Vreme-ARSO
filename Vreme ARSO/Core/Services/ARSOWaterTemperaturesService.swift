import Foundation

struct ARSOWaterTemperaturesService {
    let apiClient: APIClientProtocol

    func fetchReport() async throws -> WaterTemperatureReport {
        async let coastData = apiClient.data(for: .coastForecast)
        async let overviewData = try? await apiClient.data(for: .mountainSeaOverview)

        let slots = try parseCoastSlots(from: await coastData)
        let statusMessage = try await overviewData.flatMap(parseStatusMessage(from:))

        return WaterTemperatureReport(
            issuedAtText: slots.first?.label,
            statusMessage: statusMessage,
            slots: slots,
            sourceURL: Endpoint.coastForecast.url
        )
    }

    func parseCoastSlots(from data: Data) throws -> [WaterTemperatureSlot] {
        guard let html = String(data: data, encoding: .utf8) else {
            throw ARSOError.parsingFailed("Obalne napovedi ni bilo mogoče prebrati.")
        }

        guard let tableHTML = firstMatch(in: html, pattern: "<table[^>]*class=\"meteoSI-table\"[^>]*>(.*?)</table>") else {
            throw ARSOError.parsingFailed("Obalne tabele ni bilo mogoče razbrati.")
        }

        let rows = parseRows(from: tableHTML)
        guard let headerCells = rows.first else {
            throw ARSOError.parsingFailed("Obalna tabela je prazna.")
        }

        let labels = Array(headerCells.dropFirst()).map { $0.arsoStrippedHTML() }
        let seaTemperatureValues = rowValues(matching: "Temp. morja", in: rows).first
        let seaStateValues = rowValues(matching: "Stanje morja", in: rows).last
        let windSpeedValues = rowValues(matching: "Hitrost vetra", in: rows).first

        guard let seaTemperatureValues else {
            throw ARSOError.parsingFailed("ARSO trenutno ne objavi temperature morja.")
        }

        return zip(labels, seaTemperatureValues).enumerated().map { index, pair in
            WaterTemperatureSlot(
                id: "sea-\(index)",
                label: pair.0,
                seaTemperature: pair.1.arsoStrippedHTML(),
                seaState: seaStateValues?[safe: index]?.arsoStrippedHTML().nilIfBlank,
                windSpeed: windSpeedValues?[safe: index]?.arsoStrippedHTML().nilIfBlank
            )
        }
    }

    func parseStatusMessage(from data: Data) throws -> String? {
        guard let html = String(data: data, encoding: .utf8) else {
            return nil
        }

        if let unavailable = firstMatch(
            in: html,
            pattern: "<h3>\\s*(Temperature rek, jezer in morja.*?)\\s*</h3>"
        ) {
            return unavailable.arsoStrippedHTML()
        }

        return nil
    }

    private func rowValues(matching label: String, in rows: [[String]]) -> [[String]] {
        rows.compactMap { row in
            guard let key = row.first?.arsoStrippedHTML(),
                  key.localizedCaseInsensitiveContains(label) else {
                return nil
            }
            return Array(row.dropFirst())
        }
    }

    private func parseRows(from tableHTML: String) -> [[String]] {
        matches(in: tableHTML, pattern: "<tr>(.*?)</tr>").map { rowHTML in
            matches(in: rowHTML, pattern: "<t[hd][^>]*>(.*?)</t[hd]>")
        }
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
