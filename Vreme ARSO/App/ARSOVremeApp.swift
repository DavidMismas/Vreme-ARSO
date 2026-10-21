import SwiftUI

@main
struct ARSOVremeApp: App {
    @Environment(\.scenePhase) private var scenePhase
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
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { BackgroundWeatherRefresh.schedule(settings: settingsStore) }
            }
            .onChange(of: settingsStore.autoRefreshEnabled) { _, _ in
                BackgroundWeatherRefresh.schedule(settings: settingsStore)
            }
            .onChange(of: settingsStore.autoRefreshInterval) { _, _ in
                BackgroundWeatherRefresh.schedule(settings: settingsStore)
            }
        }
        .backgroundTask(.appRefresh(BackgroundWeatherRefresh.identifier)) {
            await BackgroundWeatherRefresh.run(container: container, settings: settingsStore, locationService: locationService)
        }
    }
}
