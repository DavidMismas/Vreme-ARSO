import Combine
import CoreLocation
import SwiftUI

struct HomeView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService
    @StateObject private var viewModel: HomeViewModel

    init(container: AppContainer, settingsStore: SettingsStore, locationService: LocationService) {
        self.container = container
        self.settingsStore = settingsStore
        self.locationService = locationService
        _viewModel = StateObject(wrappedValue: HomeViewModel(container: container))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.stationSnapshots.isEmpty {
                    LoadingStateView(title: "Nalagam vremenske podatke …")
                } else if let errorMessage = viewModel.errorMessage, viewModel.stationSnapshots.isEmpty {
                    ErrorStateView(message: errorMessage) {
                        Task { await load() }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let snapshot = selectedSnapshot {
                                CardSection(title: snapshot.station.name, systemImage: "location") {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(NumberFormatterSI.string(from: snapshot.observation.temperature, suffix: "°C"))
                                            .font(.system(size: 52, weight: .semibold, design: .rounded))

                                        Text(snapshot.observation.weatherDescription ?? "Brez opisa")
                                            .font(.title3.weight(.medium))

                                        MetricRow(label: "Občutek", value: NumberFormatterSI.string(from: snapshot.observation.apparentTemperature, suffix: "°C"))
                                        MetricRow(label: "Veter", value: windText(snapshot.observation))
                                        MetricRow(label: "Padavine", value: NumberFormatterSI.string(from: snapshot.observation.precipitation, suffix: "mm"))
                                        MetricRow(label: "Posodobljeno", value: snapshot.observation.timestamp.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Ni podatka")
                                        SourceBadge()
                                    }
                                }
                            }

                            CardSection(title: "Povzetek napovedi", systemImage: "text.alignleft") {
                                Text(viewModel.summaryForecast?.body ?? "Napoved trenutno ni na voljo.")
                                    .font(.body)
                                if let issuedAt = viewModel.summaryForecast?.issuedAt {
                                    Text("Objavljeno: \(DateFormatterSI.displayDateTime.string(from: issuedAt))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if let topWarning = viewModel.warnings.first {
                                NavigationLink {
                                    WarningsView(container: container)
                                } label: {
                                    CardSection(title: "Aktivno opozorilo", systemImage: "exclamationmark.triangle") {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(topWarning.title)
                                                .font(.headline)
                                                .foregroundStyle(topWarning.severity.color)
                                            Text(topWarning.area)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Text(topWarning.body)
                                                .font(.subheadline)
                                                .lineLimit(3)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            HStack(spacing: 12) {
                                NavigationLink {
                                    RadarView(container: container)
                                } label: {
                                    quickLink(title: "Radar", systemImage: "dot.radiowaves.left.and.right")
                                }

                                NavigationLink {
                                    ForecastTextView(container: container)
                                } label: {
                                    quickLink(title: "Tekstovna napoved", systemImage: "doc.text")
                                }
                            }

                            NavigationLink {
                                GraphicForecastsView(container: container)
                            } label: {
                                quickLink(title: "Grafične napovedi", systemImage: "square.stack.3d.up")
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await load()
                    }
                }
            }
            .navigationTitle("Vreme ARSO")
            .task {
                await load()
                locationService.requestAccessIfNeeded()
                locationService.refreshLocation()
            }
            .onChange(of: settingsStore.selectedStationID) { _, _ in }
            .onChange(of: locationService.currentLocation) { _, _ in }
        }
    }

    private var selectedSnapshot: HomeViewModel.StationSnapshotViewData? {
        viewModel.selectedSnapshot(
            preferredStationID: settingsStore.selectedStationID,
            useCurrentLocation: settingsStore.useCurrentLocation,
            currentLocation: locationService.currentLocation
        )
    }

    private func load() async {
        await viewModel.load()
    }

    private func windText(_ observation: CurrentObservation) -> String {
        let speed = NumberFormatterSI.string(from: observation.windSpeed, suffix: "m/s")
        if let direction = observation.windDirection {
            return "\(direction), \(speed)"
        }
        return speed
    }

    private func quickLink(title: String, systemImage: String) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.cardBackground, in: RoundedRectangle(cornerRadius: AppTheme.Metrics.cardCornerRadius, style: .continuous))
    }
}

@MainActor
final class HomeViewModel: ObservableObject {
    struct StationSnapshotViewData: Identifiable {
        let station: WeatherStation
        let observation: CurrentObservation
        var id: String { station.id }
    }

    @Published private(set) var stationSnapshots: [StationSnapshotViewData] = []
    @Published private(set) var summaryForecast: ForecastTextSection?
    @Published private(set) var warnings: [WarningItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let stations = container.stationsService.fetchStations()
            async let observations = container.currentWeatherService.fetchCurrentObservations()
            async let forecast = container.forecastTextService.fetchSections()
            async let warnings = container.warningsService.fetchWarnings()

            let stationsValue = try await stations
            let observationsValue = try await observations
            let sections = try await forecast
            let warningsValue = try await warnings

            let observationByStation = Dictionary(uniqueKeysWithValues: observationsValue.map { ($0.stationID, $0) })
            stationSnapshots = stationsValue.compactMap { station in
                guard let observation = observationByStation[station.id] else { return nil }
                return StationSnapshotViewData(station: station, observation: observation)
            }
            .sorted { $0.station.name < $1.station.name }

            summaryForecast = sections.first(where: { $0.type == .napoved })
            self.warnings = warningsValue
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectedSnapshot(
        preferredStationID: String?,
        useCurrentLocation: Bool,
        currentLocation: CLLocation?
    ) -> StationSnapshotViewData? {
        if let preferredStationID,
           let selected = stationSnapshots.first(where: { $0.station.id == preferredStationID }) {
            return selected
        }

        if useCurrentLocation,
           let currentLocation {
            return stationSnapshots.min { lhs, rhs in
                lhs.station.coordinate.distance(from: currentLocation) < rhs.station.coordinate.distance(from: currentLocation)
            }
        }

        return stationSnapshots.first(where: { $0.station.id == "LJUBL-ANA_BEZIGRAD_" }) ?? stationSnapshots.first
    }
}

#Preview {
    HomeView(container: .live, settingsStore: SettingsStore(), locationService: LocationService())
}
