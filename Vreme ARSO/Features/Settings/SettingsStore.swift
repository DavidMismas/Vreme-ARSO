import Combine
import CoreLocation
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var selectedStationID: String? {
        didSet {
            defaults.set(selectedStationID, forKey: Keys.selectedStationID)
            if selectedStationID == nil {
                clearSelectedStationMetadata()
            }
            syncWidgetPreferences()
        }
    }

    @Published var useSelectedFavoriteStationForPrimaryViews: Bool {
        didSet {
            defaults.set(useSelectedFavoriteStationForPrimaryViews, forKey: Keys.useSelectedFavoriteStationForPrimaryViews)
            syncWidgetPreferences()
        }
    }

    @Published var useCurrentLocation: Bool {
        didSet {
            defaults.set(useCurrentLocation, forKey: Keys.useCurrentLocation)
            syncWidgetPreferences()
        }
    }

    @Published var autoRefreshEnabled: Bool {
        didSet { defaults.set(autoRefreshEnabled, forKey: Keys.autoRefreshEnabled) }
    }

    @Published var manualLocationName: String? {
        didSet {
            defaults.set(manualLocationName, forKey: Keys.manualLocationName)
            syncWidgetPreferences()
        }
    }

    @Published var manualLocationLatitude: Double? {
        didSet {
            defaults.set(manualLocationLatitude, forKey: Keys.manualLocationLatitude)
            syncWidgetPreferences()
        }
    }

    @Published var manualLocationLongitude: Double? {
        didSet {
            defaults.set(manualLocationLongitude, forKey: Keys.manualLocationLongitude)
            syncWidgetPreferences()
        }
    }

    @Published private(set) var favoriteStationIDs: Set<String> {
        didSet {
            defaults.set(Array(favoriteStationIDs), forKey: Keys.favoriteStationIDs)
            syncWidgetPreferences()
        }
    }

    private let defaults = UserDefaults.standard
    private var selectedStationName: String? {
        didSet { defaults.set(selectedStationName, forKey: Keys.selectedStationName) }
    }
    private var selectedStationLatitude: Double? {
        didSet { defaults.set(selectedStationLatitude, forKey: Keys.selectedStationLatitude) }
    }
    private var selectedStationLongitude: Double? {
        didSet { defaults.set(selectedStationLongitude, forKey: Keys.selectedStationLongitude) }
    }

    init() {
        selectedStationID = defaults.string(forKey: Keys.selectedStationID)
        useSelectedFavoriteStationForPrimaryViews = defaults.object(forKey: Keys.useSelectedFavoriteStationForPrimaryViews) as? Bool ?? false
        useCurrentLocation = defaults.object(forKey: Keys.useCurrentLocation) as? Bool ?? true
        autoRefreshEnabled = defaults.object(forKey: Keys.autoRefreshEnabled) as? Bool ?? true
        manualLocationName = defaults.string(forKey: Keys.manualLocationName)
        manualLocationLatitude = defaults.object(forKey: Keys.manualLocationLatitude) as? Double
        manualLocationLongitude = defaults.object(forKey: Keys.manualLocationLongitude) as? Double
        favoriteStationIDs = Set(defaults.stringArray(forKey: Keys.favoriteStationIDs) ?? [])
        selectedStationName = defaults.string(forKey: Keys.selectedStationName)
        selectedStationLatitude = defaults.object(forKey: Keys.selectedStationLatitude) as? Double
        selectedStationLongitude = defaults.object(forKey: Keys.selectedStationLongitude) as? Double
        syncWidgetPreferences()
    }

    func toggleFavorite(stationID: String) {
        if favoriteStationIDs.contains(stationID) {
            favoriteStationIDs.remove(stationID)
            if selectedStationID == stationID {
                setSelectedStation(nil)
            }
        } else {
            favoriteStationIDs.insert(stationID)
        }
    }

    func isFavorite(stationID: String) -> Bool {
        favoriteStationIDs.contains(stationID)
    }

    var hasSelectedFavoriteStation: Bool {
        guard let selectedStationID else { return false }
        return favoriteStationIDs.contains(selectedStationID)
    }

    var pinnedFavoriteStationID: String? {
        guard useSelectedFavoriteStationForPrimaryViews, hasSelectedFavoriteStation else { return nil }
        return selectedStationID
    }

    var manualCoordinate: CLLocationCoordinate2D? {
        guard let manualLocationLatitude, let manualLocationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: manualLocationLatitude, longitude: manualLocationLongitude)
    }

    func saveManualLocation(name: String, latitude: Double, longitude: Double) {
        manualLocationName = name
        manualLocationLatitude = latitude
        manualLocationLongitude = longitude
    }

    func clearManualLocation() {
        manualLocationName = nil
        manualLocationLatitude = nil
        manualLocationLongitude = nil
    }

    func setSelectedStation(_ station: WeatherStation?) {
        selectedStationID = station?.id
        selectedStationName = station?.name
        selectedStationLatitude = station?.latitude
        selectedStationLongitude = station?.longitude
        syncWidgetPreferences()
    }

    func reconcileSelectedStation(with stations: [WeatherStation]) {
        guard let selectedStationID else { return }

        if let station = stations.first(where: { $0.id == selectedStationID }) {
            if selectedStationName != station.name ||
                selectedStationLatitude != station.latitude ||
                selectedStationLongitude != station.longitude {
                selectedStationName = station.name
                selectedStationLatitude = station.latitude
                selectedStationLongitude = station.longitude
                syncWidgetPreferences()
            }
        } else {
            setSelectedStation(nil)
        }
    }

    private func syncWidgetPreferences() {
        let activeSelectedStationName = pinnedFavoriteStationID == nil ? nil : selectedStationName
        let activeSelectedStationLatitude = pinnedFavoriteStationID == nil ? nil : selectedStationLatitude
        let activeSelectedStationLongitude = pinnedFavoriteStationID == nil ? nil : selectedStationLongitude

        WidgetSharedStore.syncPreferences(
            useCurrentLocation: useCurrentLocation,
            manualLocationName: manualLocationName,
            manualLatitude: manualLocationLatitude,
            manualLongitude: manualLocationLongitude,
            useSelectedFavoriteStation: pinnedFavoriteStationID != nil,
            selectedStationName: activeSelectedStationName,
            selectedStationLatitude: activeSelectedStationLatitude,
            selectedStationLongitude: activeSelectedStationLongitude
        )
    }

    private func clearSelectedStationMetadata() {
        selectedStationName = nil
        selectedStationLatitude = nil
        selectedStationLongitude = nil
    }
}

private enum Keys {
    static let selectedStationID = "selectedStationID"
    static let useSelectedFavoriteStationForPrimaryViews = "useSelectedFavoriteStationForPrimaryViews"
    static let useCurrentLocation = "useCurrentLocation"
    static let autoRefreshEnabled = "autoRefreshEnabled"
    static let favoriteStationIDs = "favoriteStationIDs"
    static let manualLocationName = "manualLocationName"
    static let manualLocationLatitude = "manualLocationLatitude"
    static let manualLocationLongitude = "manualLocationLongitude"
    static let selectedStationName = "selectedStationName"
    static let selectedStationLatitude = "selectedStationLatitude"
    static let selectedStationLongitude = "selectedStationLongitude"
}
