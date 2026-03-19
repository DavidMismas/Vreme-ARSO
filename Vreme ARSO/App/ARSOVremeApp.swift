import SwiftUI

@main
struct ARSOVremeApp: App {
    private let container = AppContainer.live
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            RootView(
                container: container,
                settingsStore: settingsStore,
                locationService: locationService
            )
        }
    }
}
