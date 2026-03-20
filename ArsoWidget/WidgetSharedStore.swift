import Foundation

enum WidgetSharedStore {
    static let appGroupID = "group.com.david.Vreme-ARSO"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    enum Keys {
        static let useCurrentLocation = "useCurrentLocation"
        static let manualLocationName = "manualLocationName"
        static let manualLocationLatitude = "manualLocationLatitude"
        static let manualLocationLongitude = "manualLocationLongitude"
        static let currentLocationLatitude = "widgetCurrentLocationLatitude"
        static let currentLocationLongitude = "widgetCurrentLocationLongitude"
    }
}
