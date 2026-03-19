import Foundation

struct TimelineItemDTO: Decodable {
    let mode: String
    let path: String
    let date: String
    let hhmm: String
    let bbox: String
    let width: String
    let height: String
    let valid: String
}

struct ARSORadarService {
    let apiClient: APIClientProtocol

    func fetchFrames() async throws -> [RadarFrame] {
        let data = try await apiClient.data(for: .radarTimeline)
        let items = try JSONDecoder().decode([TimelineItemDTO].self, from: data)

        return items.map { item in
            RadarFrame(
                id: item.date,
                timestamp: DateFormatterSI.capWithoutFraction.date(from: item.valid),
                imageURL: URL(string: "https://meteo.arso.gov.si\(item.path)")!,
                cachedLocalPath: nil,
                geoReference: FrameGeoReference(bbox: item.bbox, width: item.width, height: item.height)
            )
        }
    }
}
