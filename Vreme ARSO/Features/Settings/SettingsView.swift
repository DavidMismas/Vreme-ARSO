import SwiftUI

struct SettingsView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService
    @State private var stations: [WeatherStation] = []

    var body: some View {
        List {
            Section("Lokacija") {
                Toggle("Uporabi trenutno lokacijo", isOn: $settingsStore.useCurrentLocation)
                if !settingsStore.useCurrentLocation {
                    Picker("Privzeta postaja", selection: Binding(
                        get: { settingsStore.selectedStationID ?? "" },
                        set: { settingsStore.selectedStationID = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Ni izbrane").tag("")
                        ForEach(stations) { station in
                            Text(station.name).tag(station.id)
                        }
                    }
                }
                Button("Osveži trenutno lokacijo") {
                    locationService.requestAccessIfNeeded()
                    locationService.refreshLocation()
                }
            }

            Section("Osveževanje") {
                Toggle("Samodejno osveževanje", isOn: $settingsStore.autoRefreshEnabled)
                Text("Trenutne razmere se osvežujejo pogosteje, tekstovna napoved zmerno, radar in satelit po potrebi.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Priljubljene postaje") {
                if settingsStore.favoriteStationIDs.isEmpty {
                    Text("Še ni priljubljenih postaj.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(stations.filter { settingsStore.favoriteStationIDs.contains($0.id) }) { station in
                        Text(station.name)
                    }
                }
            }

            Section("O aplikaciji") {
                SourceBadge()
                Text("Aplikacija prikazuje ARSO podatke v nativnem SwiftUI vmesniku za Slovenijo.")
                Text("Pripravljeno za kasnejšo razširitev z widgeti, Apple Watch in potisnimi opozorili.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Nastavitve")
        .task {
            await loadStations()
        }
    }

    private func loadStations() async {
        do {
            stations = try await container.stationsService.fetchStations()
                .sorted { $0.name < $1.name }
        } catch {
            NSLog("Nastavitvenih postaj ni bilo mogoče naložiti: %@", error.localizedDescription)
        }
    }
}
