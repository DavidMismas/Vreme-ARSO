import BackgroundTasks
import Foundation

@MainActor
enum BackgroundWeatherRefresh {
    static let identifier = "com.david.Vreme-ARSO.weather-refresh"

    static func schedule(settings: SettingsStore) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        guard settings.autoRefreshEnabled else { return }
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = Date().addingTimeInterval(settings.autoRefreshInterval.seconds)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            NSLog("Osveževanje v ozadju trenutno ni na voljo: %@", error.localizedDescription)
        }
    }

    static func run(container: AppContainer, settings: SettingsStore, locationService: LocationService) async {
        schedule(settings: settings)
        guard settings.autoRefreshEnabled, !Task.isCancelled else { return }
        let model = HomeViewModel(container: container)
        model.restorePersistedStateIfAvailable()
        guard settings.autoRefreshInterval.isDue(lastUpdate: model.state?.fetchedAt) else { return }
        await model.refresh(settings: settings, locationService: locationService)
    }
}
