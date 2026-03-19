import Foundation

struct ARSOGraphicForecastService {
    let apiClient: APIClientProtocol

    func fetchGraphicForecasts() async throws -> [GraphicForecastItem] {
        try await withThrowingTaskGroup(of: GraphicForecastItem.self) { group in
            for kind in Endpoint.GraphicKind.allCases {
                group.addTask {
                    try await fetchItem(for: kind)
                }
            }

            var items: [GraphicForecastItem] = []
            for try await item in group {
                items.append(item)
            }
            return items.sorted { $0.title < $1.title }
        }
    }

    private func fetchItem(for kind: Endpoint.GraphicKind) async throws -> GraphicForecastItem {
        let data = try await apiClient.data(for: .graphicTimeline(kind: kind))
        let timeline = try JSONDecoder().decode([TimelineItemDTO].self, from: data)
        let frames = timeline.map { item in
            GraphicFrame(
                id: item.date,
                timestamp: DateFormatterSI.capWithoutFraction.date(from: item.valid),
                imageURL: URL(string: "https://meteo.arso.gov.si\(item.path)")!,
                cachedLocalPath: nil,
                geoReference: FrameGeoReference(bbox: item.bbox, width: item.width, height: item.height)
            )
        }

        return GraphicForecastItem(
            id: kind.id,
            kind: kind,
            title: kind.naslov,
            frames: frames,
            latestImageURL: frames.last?.imageURL ?? Endpoint.graphicLatest(kind: kind).url,
            updatedAt: frames.last?.timestamp,
            source: "ARSO"
        )
    }
}
