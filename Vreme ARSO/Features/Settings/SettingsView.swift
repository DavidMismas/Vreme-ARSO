import SwiftUI

struct SettingsView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService
    @State private var stations: [WeatherStation] = []
    @State private var manualLocationQuery = ""
    @State private var isResolvingPlace = false
    @State private var locationMessage: String?

    private var favoriteStations: [WeatherStation] {
        stations.filter { settingsStore.favoriteStationIDs.contains($0.id) }
    }

    var body: some View {
        List {
            Section("Lokacija") {
                Toggle("Uporabi trenutno lokacijo", isOn: $settingsStore.useCurrentLocation)

                if !settingsStore.useCurrentLocation {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Vnesi kraj", text: $manualLocationQuery)
                            .textInputAutocapitalization(.words)

                        Button {
                            Task { await resolveManualLocation() }
                        } label: {
                            if isResolvingPlace {
                                ProgressView()
                            } else {
                                Text("Shrani kraj")
                            }
                        }
                        .disabled(manualLocationQuery.nilIfBlank == nil || isResolvingPlace)

                        if let manualLocationName = settingsStore.manualLocationName {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Shranjeni kraj: \(manualLocationName)")
                                    .font(.subheadline.weight(.medium))

                                Button("Odstrani ročni kraj", role: .destructive) {
                                    settingsStore.clearManualLocation()
                                }
                                .font(.caption)
                            }
                        }

                        Text("Če za izbrani kraj ni natančnejšega koordinatnega vira, aplikacija uporabi najbližjo ARSO postajo.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Button("Osveži trenutno lokacijo") {
                    locationService.requestAccessIfNeeded()
                    locationService.refreshLocation()
                }

                if let locationMessage {
                    Text(locationMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Osveževanje") {
                Toggle("Samodejno osveževanje", isOn: $settingsStore.autoRefreshEnabled)
                Text("Radar in satelit se nalagata po potrebi, slike pa ostajajo v lokalnem cache-u za bolj miren UX.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Aplikacija se namenoma ne osvežuje prepogosto. Klici do ARSO virov so omejeni, da ne pride do preobremenitve ali IP blokade.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Priljubljene postaje") {
                if settingsStore.favoriteStationIDs.isEmpty {
                    Text("Še ni priljubljenih postaj.")
                        .foregroundStyle(.secondary)
                    Text("Dodaj jih iz zemljevida ali iz seznama razmer.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Privzeta postaja", selection: Binding(
                        get: { settingsStore.selectedStationID ?? "" },
                        set: { value in
                            let station = favoriteStations.first(where: { $0.id == value })
                            settingsStore.setSelectedStation(station)
                        }
                    )) {
                        Text("Ni izbrane").tag("")
                        ForEach(favoriteStations) { station in
                            Text(station.name).tag(station.id)
                        }
                    }

                    Toggle(
                        "Prikaži privzeto postajo na Domov in widgetu",
                        isOn: $settingsStore.useSelectedFavoriteStationForPrimaryViews
                    )
                    .disabled(!settingsStore.hasSelectedFavoriteStation)

                    Text(settingsStore.hasSelectedFavoriteStation
                         ? "Če je vključeno, Domov in widget uporabita izbrano priljubljeno postajo namesto trenutne lokacije ali ročnega kraja."
                         : "Izberi eno od priljubljenih postaj kot privzeto, če jo želiš prikazati na Domov in widgetu.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(favoriteStations) { station in
                        Text(station.name)
                    }
                }
            }

            Section("O aplikaciji") {
                SourceBadge()
                Text("Aplikacija uporablja javno dostopne vremenske podatke ARSO.")
                Text("Prikazi in vsebina so prilagojeni za prijaznejšo uporabo na telefonu.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Nastavitve")
        .task {
            await loadStations()
        }
        .appListStyle()
    }

    private func loadStations() async {
        do {
            stations = try await container.stationsService.fetchStations()
                .sorted { $0.name < $1.name }
            settingsStore.reconcileSelectedStation(with: stations)
        } catch {
            NSLog("Nastavitvenih postaj ni bilo mogoče naložiti: %@", error.localizedDescription)
        }
    }

    private func resolveManualLocation() async {
        guard let query = manualLocationQuery.nilIfBlank else { return }

        isResolvingPlace = true
        defer { isResolvingPlace = false }

        do {
            let result = try await container.locationResolver.geocode(place: query)
            settingsStore.saveManualLocation(
                name: result.name,
                latitude: result.latitude,
                longitude: result.longitude
            )
            locationMessage = "Shranjena lokacija: \(result.name)"
        } catch {
            locationMessage = error.localizedDescription
        }
    }
}
