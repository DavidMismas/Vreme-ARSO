import Foundation
import CoreLocation

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension CLLocationCoordinate2D {
    func distance(from location: CLLocation?) -> CLLocationDistance {
        guard let location else { return .greatestFiniteMagnitude }
        return CLLocation(latitude: latitude, longitude: longitude).distance(from: location)
    }
}
