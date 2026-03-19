import SwiftUI

struct RootView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService

    var body: some View {
        TabView {
            HomeView(
                container: container,
                settingsStore: settingsStore,
                locationService: locationService
            )
            .tabItem {
                Label("Domov", systemImage: "house")
            }

            CurrentWeatherView(
                container: container,
                settingsStore: settingsStore
            )
            .tabItem {
                Label("Razmere", systemImage: "thermometer.medium")
            }

            ForecastTextView(container: container)
                .tabItem {
                    Label("Napoved", systemImage: "text.book.closed")
                }

            StationsMapView(
                container: container,
                settingsStore: settingsStore,
                locationService: locationService
            )
            .tabItem {
                Label("Zemljevid", systemImage: "map")
            }

            MoreView(
                container: container,
                settingsStore: settingsStore,
                locationService: locationService
            )
            .tabItem {
                Label("Več", systemImage: "ellipsis.circle")
            }
        }
        .tint(AppTheme.Colors.accent)
    }
}

private struct MoreView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService

    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Opozorila") {
                    WarningsView(container: container)
                }

                NavigationLink("Radar") {
                    RadarView(container: container)
                }

                NavigationLink("Satelit") {
                    SatelliteView(container: container)
                }

                NavigationLink("Temperature voda") {
                    WaterTemperaturesView(container: container)
                }

                NavigationLink("Razmere v gorah") {
                    MountainConditionsView(container: container)
                }

                NavigationLink("Grafične napovedi") {
                    GraphicForecastsView(container: container)
                }

                NavigationLink("Nastavitve") {
                    SettingsView(
                        container: container,
                        settingsStore: settingsStore,
                        locationService: locationService
                    )
                }
            }
            .navigationTitle("Več")
        }
    }
}
