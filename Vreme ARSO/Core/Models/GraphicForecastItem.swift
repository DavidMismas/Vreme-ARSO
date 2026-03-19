import Foundation

struct GraphicFrame: Identifiable, Hashable, Sendable {
    let id: String
    let timestamp: Date?
    let imageURL: URL
    let cachedLocalPath: URL?
    let geoReference: FrameGeoReference?
}

struct GraphicForecastItem: Identifiable, Hashable, Sendable {
    let id: String
    let kind: Endpoint.GraphicKind
    let title: String
    let frames: [GraphicFrame]
    let latestImageURL: URL
    let updatedAt: Date?
    let source: String
}
