import Foundation

struct SatelliteFrame: Identifiable, Hashable, Sendable {
    let id: String
    let timestamp: Date?
    let imageURL: URL
    let animationURL: URL?
    let cachedLocalPath: URL?
}
