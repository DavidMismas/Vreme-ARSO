import Foundation

enum WidgetSharedStore {
    static let appGroupID = "group.com.david.Vreme-ARSO"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func cachedContent(for preferenceKey: String) -> WidgetWeatherContent? {
        guard
            let defaults,
            let data = defaults.data(forKey: persistedContentKey(for: preferenceKey))
        else {
            return nil
        }

        return try? JSONDecoder().decode(WidgetWeatherContent.self, from: data)
    }

    static func lastCachedContent() -> WidgetWeatherContent? {
        guard
            let defaults,
            let data = defaults.data(forKey: Keys.lastCachedContent)
        else {
            return nil
        }

        return try? JSONDecoder().decode(WidgetWeatherContent.self, from: data)
    }

    static func storeCachedContent(_ content: WidgetWeatherContent, for preferenceKey: String) {
        guard
            let defaults,
            let data = try? JSONEncoder().encode(content)
        else {
            return
        }

        defaults.set(data, forKey: persistedContentKey(for: preferenceKey))
        defaults.set(data, forKey: Keys.lastCachedContent)
    }

    private static func persistedContentKey(for preferenceKey: String) -> String {
        "\(Keys.cachedContentPrefix)\(preferenceKey)"
    }

    enum Keys {
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
        static let cachedContentPrefix = "widgetCachedContent."
        static let lastCachedContent = "widgetLastCachedContent"
    }
}
