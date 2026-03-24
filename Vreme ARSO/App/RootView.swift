import SwiftUI

struct RootView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService

    var body: some View {
        ZStack {
            AppTheme.Colors.screenBackground
                .ignoresSafeArea()

            TabView {
                HomeView(
                    container: container,
                    settingsStore: settingsStore,
                    locationService: locationService
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
                    .foregroundStyle(AppTheme.Colors.screenBackground.opacity(0.88))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .background(
                AppTheme.Colors.cardGradient,
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.Colors.border.opacity(0.95), lineWidth: 1)
            }
            .shadow(color: AppTheme.Colors.accent.opacity(0.08), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}
