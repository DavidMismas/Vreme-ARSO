import Foundation
import CoreLocation

extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func arsoDecodedHTML() -> String {
        self
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&deg;", with: "°")
            .replacingOccurrences(of: "&#xA;", with: "\n")
    }

    func arsoStrippedHTML() -> String {
        arsoDecodedHTML()
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
