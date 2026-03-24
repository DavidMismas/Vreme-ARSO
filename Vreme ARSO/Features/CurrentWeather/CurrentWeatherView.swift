import Combine
import SwiftUI

struct CurrentWeatherView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @StateObject private var viewModel: CurrentWeatherViewModel

    init(container: AppContainer, settingsStore: SettingsStore) {
        self.container = container
        self.settingsStore = settingsStore
        _viewModel = StateObject(wrappedValue: CurrentWeatherViewModel(container: container))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.rows.isEmpty {
                    LoadingStateView(title: "Nalagam postaje …")
                } else if let errorMessage = viewModel.errorMessage, viewModel.rows.isEmpty {
                    ErrorStateView(message: errorMessage) {
                        Task { await viewModel.load(favorites: settingsStore.favoriteStationIDs) }
                    }
                } else {
                    List(viewModel.filteredRows) { row in
                        NavigationLink {
                            CurrentWeatherDetailView(row: row)
                        } label: {
                            CurrentWeatherRowCard(row: row)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                settingsStore.toggleFavorite(stationID: row.station.id)
                                Task {
                                    await viewModel.load(favorites: settingsStore.favoriteStationIDs)
                                }
                            } label: {
                                Label(row.station.isFavorite ? "Odstrani" : "Priljubljena", systemImage: row.station.isFavorite ? "star.slash" : "star")
                            }
                            .tint(.yellow)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .searchable(text: $viewModel.searchText, prompt: "Išči po kraju ali postaji")
                    .refreshable {
                        await viewModel.load(favorites: settingsStore.favoriteStationIDs)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                    .background(AppTheme.Colors.screenGradient.ignoresSafeArea())
                }
            }
            .navigationTitle("Razmere")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.load(favorites: settingsStore.favoriteStationIDs)
            }
            .appScreenBackground()
        }
    }
}

private struct CurrentWeatherRowCard: View {
    let row: CurrentWeatherViewModel.Row

    var body: some View {
        HStack(spacing: 14) {
            WeatherSymbolView(condition: row.condition, size: 22)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(row.station.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if row.station.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.Colors.accentSecondary)
                    }
                }

                Text(row.observation.weatherDescription ?? "Brez opisa")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                Text(NumberFormatterSI.string(from: row.observation.temperature, suffix: "°C"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.screenBackground.opacity(0.88))
            }
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
}

private struct CurrentWeatherDetailView: View {
    let row: CurrentWeatherViewModel.Row

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    WeatherSymbolView(condition: row.condition, size: 28)
                    Text(row.observation.weatherDescription ?? "Brez opisa")
                        .font(.headline)
                }
            }

            Section("Postaja") {
                MetricRow(label: "Ime", value: row.station.name)
                MetricRow(label: "Nadmorska višina", value: NumberFormatterSI.string(from: row.station.elevation, suffix: "m"))
                MetricRow(label: "Regija", value: row.station.region ?? "Ni podatka")
            }

            Section("Razmere") {
                MetricRow(label: "Temperatura", value: NumberFormatterSI.string(from: row.observation.temperature, suffix: "°C"))
                MetricRow(label: "Vlaga", value: row.observation.humidity.map { "\($0) %" } ?? "Ni podatka")
                MetricRow(label: "Tlak", value: NumberFormatterSI.string(from: row.observation.pressure, suffix: "hPa"))
                MetricRow(label: "Veter", value: NumberFormatterSI.string(from: row.observation.windSpeed, suffix: "m/s"))
                MetricRow(label: "Sunki vetra", value: NumberFormatterSI.string(from: row.observation.windGust, suffix: "m/s"))
                MetricRow(label: "Smer vetra", value: row.observation.windDirection ?? "Ni podatka")
                MetricRow(label: "Padavine", value: NumberFormatterSI.string(from: row.observation.precipitation, suffix: "mm"))
                MetricRow(label: "Oblačnost", value: row.observation.cloudiness ?? "Ni podatka")
                MetricRow(label: "Posodobitev", value: row.observation.timestamp.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Ni podatka")
            }

            Section {
                SourceBadge()
            }
        }
        .navigationTitle(row.station.name)
        .navigationBarTitleDisplayMode(.inline)
        .appListStyle()
    }
}

@MainActor
final class CurrentWeatherViewModel: ObservableObject {
    struct Row: Identifiable {
        let station: WeatherStation
        let observation: CurrentObservation
        let condition: WeatherCondition
        var id: String { station.id }
    }

    @Published var searchText = ""
    @Published private(set) var rows: [Row] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    var filteredRows: [Row] {
        guard let query = searchText.nilIfBlank?.lowercased() else { return rows }
        return rows.filter {
            $0.station.name.lowercased().contains(query) || ($0.station.region?.lowercased().contains(query) ?? false)
        }
    }

    func load(favorites: Set<String>) async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let stations = container.stationsService.fetchStations()
            async let observations = container.currentWeatherService.fetchCurrentObservations()
            let stationsValue = try await stations
            let observationsValue = try await observations
            let observationByStation = Dictionary(uniqueKeysWithValues: observationsValue.map { ($0.stationID, $0) })

            rows = stationsValue.compactMap { station in
                guard let observation = observationByStation[station.id] else { return nil }
                var updatedStation = station
                updatedStation.isFavorite = favorites.contains(station.id)
                return Row(
                    station: updatedStation,
                    observation: observation,
                    condition: container.weatherIconProvider.condition(for: observation)
                )
            }
            .sorted {
                if $0.station.isFavorite != $1.station.isFavorite {
                    return $0.station.isFavorite && !$1.station.isFavorite
                }
                return $0.station.name < $1.station.name
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
