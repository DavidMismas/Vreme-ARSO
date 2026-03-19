import Combine
import CoreLocation
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published var selectedStationID: String? {
        didSet { defaults.set(selectedStationID, forKey: Keys.selectedStationID) }
    }

    @Published var useCurrentLocation: Bool {
        didSet { defaults.set(useCurrentLocation, forKey: Keys.useCurrentLocation) }
    }

    @Published var autoRefreshEnabled: Bool {
        didSet { defaults.set(autoRefreshEnabled, forKey: Keys.autoRefreshEnabled) }
    }

    @Published var manualLocationName: String? {
        didSet { defaults.set(manualLocationName, forKey: Keys.manualLocationName) }
    }

    @Published var manualLocationLatitude: Double? {
        didSet { defaults.set(manualLocationLatitude, forKey: Keys.manualLocationLatitude) }
    }

    @Published var manualLocationLongitude: Double? {
        didSet { defaults.set(manualLocationLongitude, forKey: Keys.manualLocationLongitude) }
    }

    @Published private(set) var favoriteStationIDs: Set<String> {
        didSet { defaults.set(Array(favoriteStationIDs), forKey: Keys.favoriteStationIDs) }
    }

    private let defaults = UserDefaults.standard

    init() {
        selectedStationID = defaults.string(forKey: Keys.selectedStationID)
        useCurrentLocation = defaults.object(forKey: Keys.useCurrentLocation) as? Bool ?? true
        autoRefreshEnabled = defaults.object(forKey: Keys.autoRefreshEnabled) as? Bool ?? true
        manualLocationName = defaults.string(forKey: Keys.manualLocationName)
        manualLocationLatitude = defaults.object(forKey: Keys.manualLocationLatitude) as? Double
        manualLocationLongitude = defaults.object(forKey: Keys.manualLocationLongitude) as? Double
        favoriteStationIDs = Set(defaults.stringArray(forKey: Keys.favoriteStationIDs) ?? [])
    }

    func toggleFavorite(stationID: String) {
        if favoriteStationIDs.contains(stationID) {
            favoriteStationIDs.remove(stationID)
        } else {
            favoriteStationIDs.insert(stationID)
        }
    }

    func isFavorite(stationID: String) -> Bool {
        favoriteStationIDs.contains(stationID)
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
}

private enum Keys {
    static let selectedStationID = "selectedStationID"
    static let useCurrentLocation = "useCurrentLocation"
    static let autoRefreshEnabled = "autoRefreshEnabled"
    static let favoriteStationIDs = "favoriteStationIDs"
    static let manualLocationName = "manualLocationName"
    static let manualLocationLatitude = "manualLocationLatitude"
    static let manualLocationLongitude = "manualLocationLongitude"
}
