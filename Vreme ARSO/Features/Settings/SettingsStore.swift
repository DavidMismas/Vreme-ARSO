import Combine
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

    @Published private(set) var favoriteStationIDs: Set<String> {
        didSet { defaults.set(Array(favoriteStationIDs), forKey: Keys.favoriteStationIDs) }
    }

    private let defaults = UserDefaults.standard

    init() {
        selectedStationID = defaults.string(forKey: Keys.selectedStationID)
        useCurrentLocation = defaults.object(forKey: Keys.useCurrentLocation) as? Bool ?? true
        autoRefreshEnabled = defaults.object(forKey: Keys.autoRefreshEnabled) as? Bool ?? true
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
}

private enum Keys {
    static let selectedStationID = "selectedStationID"
    static let useCurrentLocation = "useCurrentLocation"
    static let autoRefreshEnabled = "autoRefreshEnabled"
    static let favoriteStationIDs = "favoriteStationIDs"
}
