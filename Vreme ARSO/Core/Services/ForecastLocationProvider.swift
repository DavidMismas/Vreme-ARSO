import CoreLocation
import Foundation

protocol ForecastLocationProvider {
    func nearestStation(to coordinate: CLLocationCoordinate2D, in stations: [WeatherStation]) -> WeatherStation?
}

struct StationForecastLocationProvider: ForecastLocationProvider {
    func nearestStation(to coordinate: CLLocationCoordinate2D, in stations: [WeatherStation]) -> WeatherStation? {
        let reference = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        return stations.min { lhs, rhs in
            lhs.coordinate.distance(from: reference) < rhs.coordinate.distance(from: reference)
        }
    }
}
