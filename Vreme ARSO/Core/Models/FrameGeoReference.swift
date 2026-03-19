import CoreGraphics
import Foundation

struct FrameGeoReference: Hashable, Sendable {
    let minLatitude: Double
    let minLongitude: Double
    let maxLatitude: Double
    let maxLongitude: Double
    let pixelWidth: Double?
    let pixelHeight: Double?

    init?(
        bbox: String,
        width: String? = nil,
        height: String? = nil
    ) {
        let values = bbox
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

        guard values.count == 4 else { return nil }

        minLatitude = min(values[0], values[2])
        minLongitude = min(values[1], values[3])
        maxLatitude = max(values[0], values[2])
        maxLongitude = max(values[1], values[3])
        pixelWidth = width.flatMap(Double.init)
        pixelHeight = height.flatMap(Double.init)
    }

    var aspectRatio: CGFloat? {
        guard let pixelWidth, let pixelHeight, pixelHeight > 0 else { return nil }
        return CGFloat(pixelWidth / pixelHeight)
    }

    func normalizedPosition(latitude: Double, longitude: Double) -> CGPoint? {
        let latitudeSpan = maxLatitude - minLatitude
        let longitudeSpan = maxLongitude - minLongitude
        guard latitudeSpan > 0, longitudeSpan > 0 else { return nil }

        let x = (longitude - minLongitude) / longitudeSpan
        let y = 1 - ((latitude - minLatitude) / latitudeSpan)

        guard (-0.05...1.05).contains(x), (-0.05...1.05).contains(y) else { return nil }

        return CGPoint(
            x: min(max(x, 0), 1),
            y: min(max(y, 0), 1)
        )
    }
}
