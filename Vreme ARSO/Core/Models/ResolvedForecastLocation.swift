import CoreLocation
import Foundation

enum ForecastLocationSource: String, Sendable {
    case currentLocation
    case manualPlace
    case station
}

struct ResolvedForecastLocation: Sendable {
    let displayName: String
    let detailText: String?
    let source: ForecastLocationSource
    let coordinate: CLLocationCoordinate2D?
    let nearestStation: WeatherStation?
    let observation: CurrentObservation?
}
