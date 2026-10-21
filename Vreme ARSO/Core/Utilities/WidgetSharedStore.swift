import CoreLocation
import Foundation
import WidgetKit

enum WidgetSharedStore {
    static let appGroupID = "group.com.david.Vreme-ARSO"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func syncSupplementPreferences(kind: WidgetSupplementKind, snowID: String, snowName: String, airID: String, airName: String) {
        guard let sharedDefaults else { return }
        sharedDefaults.set(kind.rawValue, forKey: "widgetSupplementKind")
        sharedDefaults.set(snowID, forKey: "widgetSnowStationID")
        sharedDefaults.set(snowName, forKey: "widgetSnowStationName")
        sharedDefaults.set(airID, forKey: "widgetAirStationID")
        sharedDefaults.set(airName, forKey: "widgetAirStationName")
    }

    static func syncPreferences(
        useCurrentLocation: Bool,
        autoRefreshEnabled: Bool,
        autoRefreshHours: Int,
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
        sharedDefaults.set(autoRefreshHours, forKey: Keys.autoRefreshHours)
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

    static func weatherDidRefresh() {
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "widgetRefreshGeneration")
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .weatherDataDidRefresh, object: nil)
    }

    static func syncCurrentLocation(_ location: CLLocation?) {
        guard let sharedDefaults else { return }
        guard let location else {
            sharedDefaults.removeObject(forKey: Keys.currentLocationLatitude)
            sharedDefaults.removeObject(forKey: Keys.currentLocationLongitude)
            return
        }

        sharedDefaults.set(location.coordinate.latitude, forKey: Keys.currentLocationLatitude)
        sharedDefaults.set(location.coordinate.longitude, forKey: Keys.currentLocationLongitude)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

private enum Keys {
    static let useCurrentLocation = "useCurrentLocation"
    static let autoRefreshHours = "autoRefreshHours"
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


extension Notification.Name {
    static let weatherDataDidRefresh = Notification.Name("weatherDataDidRefresh")
}
