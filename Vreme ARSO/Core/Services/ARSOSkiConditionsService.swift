import Foundation

struct ARSOSkiConditionsService {
    let apiClient: APIClientProtocol
    let xmlParser: XMLParserService

    func fetchReport() async throws -> SkiConditionsReport {
        let data = try await apiClient.data(for: .observationsOverview)
        let root = try xmlParser.parse(data: data)
        let locations = root.children(named: "metData")
            .compactMap(makeLocation(from:))
            .sorted {
                let leftSnow = $0.snowDepthCentimeters ?? -1
                let rightSnow = $1.snowDepthCentimeters ?? -1
                if leftSnow != rightSnow {
                    return leftSnow > rightSnow
                }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

        let issuedAt = locations.compactMap(\.updatedAt).max()

        return SkiConditionsReport(
            issuedAt: issuedAt,
            locations: locations,
            sourceURL: Endpoint.observationsOverview.url
        )
    }

    private func makeLocation(from node: XMLNode) -> SkiConditionLocation? {
        let geoType = node.textValue(forChild: "domain_geoType")?.lowercased() ?? ""
        let rawName = node.textValue(forChild: "domain_longTitle")
            ?? node.textValue(forChild: "domain_title")
            ?? node.textValue(forChild: "domain_shortTitle")
            ?? "Neznana postaja"

        let snowDepth = Int(node.textValue(forChild: "snow") ?? "")
        let newSnow = Int(node.textValue(forChild: "snowNew_val") ?? "")

        guard isRelevantStation(name: rawName, geoType: geoType, snowDepth: snowDepth, newSnow: newSnow) else {
            return nil
        }

        return SkiConditionLocation(
            id: node.textValue(forChild: "domain_meteosiId") ?? rawName,
            name: displayName(for: rawName),
            subtitle: subtitle(for: rawName, geoType: geoType),
            snowDepthCentimeters: snowDepth,
            newSnowCentimeters: newSnow,
            temperature: Double(node.textValue(forChild: "t") ?? ""),
            weatherDescription: node.textValue(forChild: "nn_shortText-wwsyn_longText") ?? node.textValue(forChild: "nn_shortText"),
            weatherSymbol: node.textValue(forChild: "nn_icon-wwsyn_icon") ?? node.textValue(forChild: "nn_icon"),
            updatedAt: DateFormatterSI.parseARSODate(node.textValue(forChild: "tsUpdated"))
        )
    }

    private func isRelevantStation(name: String, geoType: String, snowDepth: Int?, newSnow: Int?) -> Bool {
        let normalized = name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "sl_SI")).lowercased()
        let knownSkiAdjecentNames = [
            "vogel",
            "ratece",
            "kredarica",
            "vojsko",
            "lisca",
            "krvavec",
            "rogla",
            "kanin"
        ]

        if knownSkiAdjecentNames.contains(where: normalized.contains) {
            return true
        }

        if ["mountain", "mountain-valley"].contains(geoType) {
            return true
        }

        return snowDepth != nil || newSnow != nil
    }

    private func displayName(for rawName: String) -> String {
        switch rawName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "sl_SI")).lowercased() {
        case let value where value.contains("ratece"):
            return "Rateče"
        case let value where value.contains("vogel"):
            return "Vogel"
        case let value where value.contains("kredarica"):
            return "Kredarica"
        case let value where value.contains("vojsko"):
            return "Vojsko"
        case let value where value.contains("lisca"):
            return "Lisca"
        default:
            return rawName
        }
    }

    private func subtitle(for rawName: String, geoType: String) -> String? {
        let normalized = rawName.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "sl_SI")).lowercased()
        if normalized.contains("ratece") {
            return "Postaja za območje Kranjske Gore"
        }
        if normalized.contains("vogel") {
            return "Postaja nad Bohinjem"
        }
        if normalized.contains("vojsko") {
            return "Postaja za idrijsko hribovje"
        }
        if normalized.contains("lisca") {
            return "Postaja za Posavsko hribovje"
        }
        if geoType == "mountain" {
            return "Gorska ARSO postaja"
        }
        if geoType == "mountain-valley" {
            return "Dolina ob gorskem območju"
        }
        return "ARSO postaja s snežnimi podatki"
    }
}
