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
        autoRefreshEnabled: Bool,
        manualLocationName: String?,
        manualLatitude: Double?,
        manualLongitude: Double?,
        useSelectedFavoriteStation: Bool,
        selectedStationName: String?,
        selectedStationLatitude: Double?,
        selectedStationLongitude: Double?
    ) {
        guard let sharedDefaults else { return }

        sharedDefaults.set(useCurrentLocation, forKey: Keys.useCurrentLocation)
        sharedDefaults.set(autoRefreshEnabled, forKey: Keys.autoRefreshEnabled)
        sharedDefaults.set(manualLocationName, forKey: Keys.manualLocationName)
        sharedDefaults.set(manualLatitude, forKey: Keys.manualLocationLatitude)
        sharedDefaults.set(manualLongitude, forKey: Keys.manualLocationLongitude)
        sharedDefaults.set(useSelectedFavoriteStation, forKey: Keys.useSelectedFavoriteStation)
        sharedDefaults.set(selectedStationName, forKey: Keys.selectedStationName)
        sharedDefaults.set(selectedStationLatitude, forKey: Keys.selectedStationLatitude)
        sharedDefaults.set(selectedStationLongitude, forKey: Keys.selectedStationLongitude)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func syncCurrentLocation(_ location: CLLocation?) {
        guard
            let sharedDefaults,
            let location
        else {
            return
        }

        sharedDefaults.set(location.coordinate.latitude, forKey: Keys.currentLocationLatitude)
        sharedDefaults.set(location.coordinate.longitude, forKey: Keys.currentLocationLongitude)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private enum Keys {
    static let useCurrentLocation = "useCurrentLocation"
    static let autoRefreshEnabled = "autoRefreshEnabled"
    static let manualLocationName = "manualLocationName"
    static let manualLocationLatitude = "manualLocationLatitude"
    static let manualLocationLongitude = "manualLocationLongitude"
    static let useSelectedFavoriteStation = "useSelectedFavoriteStation"
    static let selectedStationName = "selectedStationName"
    static let selectedStationLatitude = "selectedStationLatitude"
    static let selectedStationLongitude = "selectedStationLongitude"
    static let currentLocationLatitude = "widgetCurrentLocationLatitude"
    static let currentLocationLongitude = "widgetCurrentLocationLongitude"
}
