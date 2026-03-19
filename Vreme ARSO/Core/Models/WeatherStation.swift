import Foundation
import CoreLocation

struct WeatherStation: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let elevation: Double?
    let region: String?
    var isFavorite: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
