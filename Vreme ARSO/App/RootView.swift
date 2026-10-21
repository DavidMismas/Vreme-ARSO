import SwiftUI

struct RootView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var homeViewModel: HomeViewModel

    init(container: AppContainer, settingsStore: SettingsStore, locationService: LocationService) {
        self.container = container
        self.settingsStore = settingsStore
        self.locationService = locationService
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(container: container))
    }

    private var refreshTaskID: String {
        "\(scenePhase)|\(settingsStore.autoRefreshEnabled)|\(settingsStore.autoRefreshInterval.rawValue)|\(settingsStore.homeLocationPreferenceKey)"
    }

    @State private var atmosphere: WeatherAtmosphere = .cloudy
    @State private var hasCheckedPrecipitationThisLaunch = false

    var body: some View {
        ZStack {
            AppTheme.Colors.screenBackground
                .ignoresSafeArea()

            TabView {
                HomeView(
                    container: container,
                    settingsStore: settingsStore,
                    locationService: locationService,
                    viewModel: homeViewModel
                )
                .appTabBarStyle()
                .tabItem {
                    Label("Domov", systemImage: "house")
                }

                CurrentWeatherView(
                    container: container,
                    settingsStore: settingsStore
                )
                .appTabBarStyle()
                .tabItem {
                    Label("Razmere", systemImage: "thermometer.medium")
                }

                ForecastTextView(container: container)
                    .appTabBarStyle()
                    .tabItem {
                        Label("Napoved", systemImage: "text.book.closed")
                    }

                StationsMapView(
                    container: container,
                    settingsStore: settingsStore,
                    locationService: locationService
                )
                .appTabBarStyle()
                .tabItem {
                    Label("Zemljevid", systemImage: "map")
                }

                MoreView(
                    container: container,
                    settingsStore: settingsStore,
                    locationService: locationService
                )
                .appTabBarStyle()
                .tabItem {
                    Label("Več", systemImage: "ellipsis.circle")
                }
            }
            .tint(AppTheme.Colors.accent)
        }
        .appScreenBackground()
        .environment(\.weatherAtmosphere, atmosphere)
        .task(id: refreshTaskID) {
            guard scenePhase == .active else { return }
            locationService.requestAccessIfNeeded()
            if homeViewModel.state == nil {
                homeViewModel.restorePersistedStateIfAvailable()
            }
            while !Task.isCancelled {
                let canRetry = homeViewModel.lastRefreshAttempt.map { Date().timeIntervalSince($0) >= 300 } ?? true
                let needsInitialPrecipitation = !hasCheckedPrecipitationThisLaunch && homeViewModel.state?.precipitation == nil
                if canRetry && (homeViewModel.state == nil || needsInitialPrecipitation || (settingsStore.autoRefreshEnabled && settingsStore.autoRefreshInterval.isDue(lastUpdate: homeViewModel.state?.fetchedAt))) {
                    hasCheckedPrecipitationThisLaunch = true
                    await homeViewModel.refresh(settings: settingsStore, locationService: locationService)
                }
                do { try await Task.sleep(for: .seconds(30)) }
                catch { return }
            }
        }
        .onChange(of: settingsStore.homeLocationPreferenceKey) { _, _ in
            Task { await homeViewModel.refresh(settings: settingsStore, locationService: locationService) }
        }
        .onChange(of: locationService.authorizationStatus) { _, status in
            guard scenePhase == .active, settingsStore.useCurrentLocation,
                  status == .authorizedWhenInUse || status == .authorizedAlways else { return }
            Task { await homeViewModel.refresh(settings: settingsStore, locationService: locationService) }
        }
        .onPreferenceChange(WeatherAtmospherePreference.self) { value in
            if let value { atmosphere = value }
        }
    }
}

private struct MoreView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    MoreLinkRow(
                        title: "Opozorila",
                        subtitle: "Aktivna vremenska opozorila",
                        systemImage: "exclamationmark.triangle.fill"
                    ) {
                        WarningsView(container: container)
                    }

                    MoreLinkRow(
                        title: "Padavine po postajah",
                        subtitle: "Meritve padavin na ARSO postajah",
                        systemImage: "drop.fill"
                    ) {
                        PrecipitationStationsView(container: container)
                    }

                    MoreLinkRow(
                        title: "Radar",
                        subtitle: "Padavine in gibanje oblakov",
                        systemImage: "dot.radiowaves.left.and.right"
                    ) {
                        RadarView(container: container)
                    }

                    MoreLinkRow(
                        title: "Satelit",
                        subtitle: "Zadnja slika in animacija",
                        systemImage: "globe.europe.africa.fill"
                    ) {
                        SatelliteView(container: container)
                    }

                    MoreLinkRow(
                        title: "Čistost zraka",
                        subtitle: "Meritve delcev in plinov po ARSO postajah",
                        systemImage: "aqi.medium"
                    ) {
                        AirQualityView(container: container)
                    }

                    MoreLinkRow(
                        title: "Temperature voda",
                        subtitle: "Morje in druga kopalna območja",
                        systemImage: "water.waves"
                    ) {
                        WaterTemperaturesView(container: container)
                    }

                    MoreLinkRow(
                        title: "Razmere v gorah",
                        subtitle: "Gorska napoved in razmere",
                        systemImage: "mountain.2.fill"
                    ) {
                        MountainConditionsView(container: container)
                    }

                    MoreLinkRow(
                        title: "Sneg in smučišča",
                        subtitle: "Snežne postaje ob smučiščih in v gorah",
                        systemImage: "snowflake"
                    ) {
                        SkiConditionsView(container: container)
                    }

                    MoreLinkRow(
                        title: "Grafične napovedi",
                        subtitle: "Barvni prikazi vremena po Sloveniji",
                        systemImage: "chart.line.uptrend.xyaxis"
                    ) {
                        GraphicForecastsView(container: container)
                    }

                    MoreLinkRow(
                        title: "Nastavitve",
                        subtitle: "Lokacija, osveževanje in widget",
                        systemImage: "gearshape.fill"
                    ) {
                        SettingsView(
                            container: container,
                            settingsStore: settingsStore,
                            locationService: locationService
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Dodatno")
            .navigationBarTitleDisplayMode(.inline)
            .appScreenBackground()
        }
    }
}

private struct MoreLinkRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @ViewBuilder let destination: Destination

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder destination: () -> Destination
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.destination = destination()
    }

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accent.opacity(0.14))
                        .frame(width: 44, height: 44)

                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(AppTheme.Colors.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .appCardSurface(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }
}
