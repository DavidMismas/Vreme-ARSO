import Foundation

struct ARSOWarningsService {
    let apiClient: APIClientProtocol
    let xmlParser: XMLParserService

    private let regionIDs = [
        "SLOVENIA_SOUTH-EAST",
        "SLOVENIA_SOUTH-WEST",
        "SLOVENIA_MIDDLE",
        "SLOVENIA_NORTH-EAST",
        "SLOVENIA_NORTH-WEST"
    ]

    func fetchWarnings() async throws -> [WarningItem] {
        let results = try await withThrowingTaskGroup(of: [WarningItem].self) { group in
            for regionID in regionIDs {
                group.addTask {
                    try await fetchWarnings(for: regionID)
                }
            }

            var collected: [WarningItem] = []
            for try await items in group {
                collected.append(contentsOf: items)
            }
            return collected
        }

        return results.sorted {
            if $0.severity != $1.severity {
                return $0.severity > $1.severity
            }
            return ($0.validFrom ?? .distantPast) > ($1.validFrom ?? .distantPast)
        }
    }

    private func fetchWarnings(for regionID: String) async throws -> [WarningItem] {
        let data = try await apiClient.data(for: .warningRegionCAP(regionID: regionID))
        let root = try xmlParser.parse(data: data)

        let alertID = root.textValue(forChild: "identifier") ?? regionID

        return root.children(named: "info").compactMap { infoNode in
            guard infoNode.textValue(forChild: "language") == "sl" else { return nil }

            let title = infoNode.textValue(forChild: "headline") ?? infoNode.textValue(forChild: "event") ?? "Opozorilo"
            let bodyParts = [infoNode.textValue(forChild: "description"), infoNode.textValue(forChild: "instruction")]
                .compactMap { $0?.nilIfBlank }
            let severity = Self.mapSeverity(infoNode.textValue(forChild: "severity"))
            let areaNode = infoNode.firstChild(named: "area")
            let polygons = areaNode?.children(named: "polygon").compactMap(Self.parsePolygon) ?? []
            let eventType = infoNode.parameters["awareness_type"] ?? infoNode.textValue(forChild: "event") ?? ""

            return WarningItem(
                id: "\(alertID)-\(eventType)-\(infoNode.textValue(forChild: "language") ?? "sl")",
                title: title,
                severity: severity,
                area: areaNode?.textValue(forChild: "areaDesc") ?? "Slovenija",
                validFrom: DateFormatterSI.parseCAP(infoNode.textValue(forChild: "onset") ?? infoNode.textValue(forChild: "effective")),
                validTo: DateFormatterSI.parseCAP(infoNode.textValue(forChild: "expires")),
                body: bodyParts.joined(separator: "\n\n").nilIfBlank ?? "Brez dodatnega opisa.",
                eventType: eventType,
                polygons: polygons
            )
        }
    }

    private static func mapSeverity(_ value: String?) -> WarningSeverity {
        switch value?.lowercased() {
        case "minor":
            return .minor
        case "moderate":
            return .moderate
        case "severe":
            return .severe
        case "extreme":
            return .extreme
        default:
            return .unknown
        }
    }

    private static func parsePolygon(_ node: XMLNode) -> [CoordinatePoint]? {
        let pairs = node.text
            .split(separator: " ")
            .compactMap { pair -> CoordinatePoint? in
                let components = pair.split(separator: ",")
                guard let latitudeString = components[safe: 0],
                      let longitudeString = components[safe: 1],
                      let latitude = Double(latitudeString),
                      let longitude = Double(longitudeString) else {
                    return nil
                }
                return CoordinatePoint(latitude: latitude, longitude: longitude)
            }

        return pairs.isEmpty ? nil : pairs
    }
}

private extension XMLNode {
    var parameters: [String: String] {
        children(named: "parameter").reduce(into: [:]) { partialResult, node in
            guard let key = node.textValue(forChild: "valueName"),
                  let value = node.textValue(forChild: "value") else {
                return
            }
            partialResult[key] = value
        }
    }
}
