import Foundation

struct MapOverlayItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let coordinates: [CoordinatePoint]
}
