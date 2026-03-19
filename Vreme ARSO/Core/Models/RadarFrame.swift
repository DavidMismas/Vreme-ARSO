import Foundation

struct RadarFrame: Identifiable, Hashable, Sendable {
    let id: String
    let timestamp: Date?
    let imageURL: URL
    let cachedLocalPath: URL?
    let geoReference: FrameGeoReference?
}
