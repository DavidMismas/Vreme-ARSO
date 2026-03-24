import SwiftUI

@main
struct ARSOVremeApp: App {
    private let container = AppContainer.live
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var locationService = LocationService()

    init() {
        AppTheme.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                container: container,
                settingsStore: settingsStore,
                locationService: locationService
            )
            .preferredColorScheme(.dark)
        }
    }
}
