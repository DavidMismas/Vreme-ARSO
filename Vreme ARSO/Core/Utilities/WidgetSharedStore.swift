import CoreLocation
import Foundation
import WidgetKit

enum WidgetSharedStore {
    static let appGroupID = "group.com.david.Vreme-ARSO"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func syncPreferences(
        useCurrentLocation: Bool,
        manualLocationName: String?,
        manualLatitude: Double?,
        manualLongitude: Double?
    ) {
        guard let sharedDefaults else { return }

        sharedDefaults.set(useCurrentLocation, forKey: Keys.useCurrentLocation)
        sharedDefaults.set(manualLocationName, forKey: Keys.manualLocationName)
        sharedDefaults.set(manualLatitude, forKey: Keys.manualLocationLatitude)
        sharedDefaults.set(manualLongitude, forKey: Keys.manualLocationLongitude)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func syncCurrentLocation(_ location: CLLocation?) {
        guard let sharedDefaults else { return }

        sharedDefaults.set(location?.coordinate.latitude, forKey: Keys.currentLocationLatitude)
        sharedDefaults.set(location?.coordinate.longitude, forKey: Keys.currentLocationLongitude)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private enum Keys {
    static let useCurrentLocation = "useCurrentLocation"
    static let manualLocationName = "manualLocationName"
    static let manualLocationLatitude = "manualLocationLatitude"
    static let manualLocationLongitude = "manualLocationLongitude"
    static let currentLocationLatitude = "widgetCurrentLocationLatitude"
    static let currentLocationLongitude = "widgetCurrentLocationLongitude"
}
