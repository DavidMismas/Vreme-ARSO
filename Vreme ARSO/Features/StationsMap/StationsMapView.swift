import Combine
import MapKit
import SwiftUI

struct StationsMapView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService
    @StateObject private var viewModel: StationsMapViewModel
    @State private var selectedStation: StationsMapViewModel.MapStation?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.15, longitude: 14.95),
            span: MKCoordinateSpan(latitudeDelta: 2.3, longitudeDelta: 2.4)
        )
    )

    init(container: AppContainer, settingsStore: SettingsStore, locationService: LocationService) {
        self.container = container
        self.settingsStore = settingsStore
        self.locationService = locationService
        _viewModel = StateObject(wrappedValue: StationsMapViewModel(container: container))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Map(position: $cameraPosition, interactionModes: .all) {
                    UserAnnotation()

                    ForEach(viewModel.stations) { station in
                        Annotation(station.station.name, coordinate: station.station.coordinate, anchor: .bottom) {
                            Button {
                                selectedStation = station
                            } label: {
                                StationMapAnnotationView(
                                    name: station.station.name,
                                    isSelected: selectedStation?.id == station.id,
                                    isFavorite: station.station.isFavorite
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .mapStyle(.standard)
                .ignoresSafeArea(edges: .bottom)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Zemljevid postaj")
                            .font(.title2.weight(.semibold))
                        Text(selectedStation?.station.name ?? "Tapnite postajo za podrobnosti.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Spacer()

                    Button {
                        locationService.requestAccessIfNeeded()
                        locationService.refreshLocation()
                        if let nearest = viewModel.nearestStation(to: locationService.currentLocation) {
                            cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: nearest.station.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.6, longitudeDelta: 0.6)
                                )
                            )
                            selectedStation = nearest
                        }
                    } label: {
                        Label("Najbližja postaja", systemImage: "location.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .navigationTitle("Zemljevid postaj")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedStation) { station in
                NavigationStack {
                    List {
                        Section(station.station.name) {
                            MetricRow(label: "Temperatura", value: NumberFormatterSI.string(from: station.observation?.temperature, suffix: "°C"))
                            MetricRow(label: "Vlaga", value: station.observation?.humidity.map { "\($0) %" } ?? "Ni podatka")
                            MetricRow(label: "Veter", value: NumberFormatterSI.string(from: station.observation?.windSpeed, suffix: "m/s"))
                            MetricRow(label: "Tlak", value: NumberFormatterSI.string(from: station.observation?.pressure, suffix: "hPa"))
                        }
                        Section {
                            Button("Nastavi kot privzeto postajo") {
                                settingsStore.setSelectedStation(station.station)
                            }
                        }
                    }
                    .navigationTitle(station.station.name)
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationDetents([.medium, .large])
            }
            .task {
                await viewModel.load(favorites: settingsStore.favoriteStationIDs)
                locationService.requestAccessIfNeeded()
                locationService.refreshLocation()
            }
        }
    }
}

private struct StationMapAnnotationView: View {
    let name: String
    let isSelected: Bool
    let isFavorite: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                .font(.title2)
                .foregroundStyle(isSelected ? AppTheme.Colors.accent : .white)
                .padding(4)
                .background(Color.black.opacity(isSelected ? 0.68 : 0.56), in: Circle())

            if isSelected || isFavorite {
                Text(name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.74), in: Capsule())
            }
        }
        .shadow(color: Color.black.opacity(0.24), radius: 8, y: 3)
    }
}

@MainActor
final class StationsMapViewModel: ObservableObject {
    struct MapStation: Identifiable {
        let station: WeatherStation
        let observation: CurrentObservation?
        var id: String { station.id }
    }

    @Published private(set) var stations: [MapStation] = []

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    func load(favorites: Set<String>) async {
        do {
            async let stations = container.stationsService.fetchStations()
            async let observations = container.currentWeatherService.fetchCurrentObservations()
            let stationValues = try await stations
            let observationValues = try await observations
            let lookup = Dictionary(uniqueKeysWithValues: observationValues.map { ($0.stationID, $0) })
            self.stations = stationValues.map { station in
                var updatedStation = station
                updatedStation.isFavorite = favorites.contains(station.id)
                return MapStation(station: updatedStation, observation: lookup[station.id])
            }
        } catch {
            NSLog("Zemljevida ni bilo mogoče naložiti: %@", error.localizedDescription)
        }
    }

    func nearestStation(to location: CLLocation?) -> MapStation? {
        guard let location else { return nil }
        return stations.min { lhs, rhs in
            lhs.station.coordinate.distance(from: location) < rhs.station.coordinate.distance(from: location)
        }
    }
}
