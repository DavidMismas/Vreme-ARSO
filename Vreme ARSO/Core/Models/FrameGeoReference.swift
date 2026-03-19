import CoreGraphics
import Foundation

protocol GeoCoordinateRepresentable {
    var latitude: Double { get }
    var longitude: Double { get }
}

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

    func aspectRatio(croppedTo normalizedRect: CGRect?) -> CGFloat? {
        guard let pixelWidth, let pixelHeight, pixelHeight > 0 else { return nil }

        let rect = normalizedRect ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        guard rect.width > 0, rect.height > 0 else { return nil }

        return CGFloat((pixelWidth * rect.width) / (pixelHeight * rect.height))
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

    func normalizedBounds<T: GeoCoordinateRepresentable>(for items: [T]) -> CGRect? {
        let points = items.compactMap { item in
            normalizedPosition(latitude: item.latitude, longitude: item.longitude)
        }

        guard let first = points.first else { return nil }

        var minX = first.x
        var maxX = first.x
        var minY = first.y
        var maxY = first.y

        for point in points.dropFirst() {
            minX = min(minX, point.x)
            maxX = max(maxX, point.x)
            minY = min(minY, point.y)
            maxY = max(maxY, point.y)
        }

        return CGRect(
            x: minX,
            y: minY,
            width: max(maxX - minX, 0.001),
            height: max(maxY - minY, 0.001)
        )
    }
}
