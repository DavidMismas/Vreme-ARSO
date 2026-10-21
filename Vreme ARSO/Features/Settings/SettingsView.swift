import SwiftUI

struct SettingsView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService
    @State private var stations: [WeatherStation] = []
    @State private var widgetStations: [WidgetStationChoice] = []
    @State private var widgetStationsLoading = false
    @State private var widgetStationsError: String?
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
                Picker("Pogostost", selection: $settingsStore.autoRefreshInterval) {
                    ForEach(AutoRefreshInterval.allCases) { interval in
                        Text(interval.title).tag(interval)
                    }
                }
                .disabled(!settingsStore.autoRefreshEnabled)
                Text("Ob osvežitvi se posodobijo vreme, trenutna lokacija (če je vključena) in widgeti. V ozadju čas osvežitve določa iOS; ob vrnitvi v aplikacijo preverimo, ali je čas za novo osvežitev.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            widgetSupplementSection

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
                Text("Aplikacija uporablja podatke ARSO - Agencija Republike Slovenije za okolje.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Nastavitve")
        .task {
            await loadStations()
        }
        .task(id: settingsStore.widgetSupplementKind) {
            await loadWidgetStations()
        }
        .appListStyle()
    }

    private var widgetSupplementSection: some View {
        Section("Dodatni podatek na widgetu") {
            Picker("Podatek", selection: $settingsStore.widgetSupplementKind) {
                ForEach(WidgetSupplementKind.allCases) { kind in
                    Label(kind.title, systemImage: kind.symbol).tag(kind)
                }
            }
            if settingsStore.widgetSupplementKind == .sea {
                LabeledContent("Območje", value: "Obala")
                Text("Temperatura morja iz obalne napovedi ARSO. Ta vir nima izbire posamezne merilne postaje.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Picker("Merilna postaja", selection: Binding(
                    get: { selectedWidgetStationID },
                    set: { id in
                        let name = widgetStations.first(where: { $0.id == id })?.name ?? ""
                        settingsStore.selectWidgetStation(kind: settingsStore.widgetSupplementKind, id: id, name: name)
                    }
                )) {
                    Text("Izberi postajo").tag("")
                    if !selectedWidgetStationID.isEmpty && !widgetStations.contains(where: { $0.id == selectedWidgetStationID }) {
                        Text(selectedWidgetStationName).tag(selectedWidgetStationID)
                    }
                    ForEach(widgetStations) { station in
                        Text(station.name).tag(station.id)
                    }
                }
                .pickerStyle(.navigationLink)
                if widgetStationsLoading {
                    ProgressView("Nalagam merilne postaje …")
                }
                if let widgetStationsError {
                    Text(widgetStationsError).font(.caption).foregroundStyle(.secondary)
                    Button("Poskusi znova") { Task { await loadWidgetStations() } }
                }
                Text(settingsStore.widgetSupplementKind == .snow
                     ? "Skupna višina snežne odeje v cm na izbrani ARSO postaji. Manjkajoča meritev ne pomeni 0 cm."
                     : "Koncentracija delcev PM2.5 v µg/m³; če ni na voljo, se prikaže PM10. To je posamezna meritev, ne celoviti indeks kakovosti zraka.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Ta postaja velja samo za dodatni podatek na widgetu. Izbira postaje za sneg in za zrak se shrani ločeno.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text("Prikazano na srednjem in velikem widgetu.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var selectedWidgetStationID: String {
        settingsStore.widgetSupplementKind == .snow ? settingsStore.widgetSnowStationID : settingsStore.widgetAirStationID
    }

    private var selectedWidgetStationName: String {
        settingsStore.widgetSupplementKind == .snow ? settingsStore.widgetSnowStationName : settingsStore.widgetAirStationName
    }

    private func loadWidgetStations() async {
        let kind = settingsStore.widgetSupplementKind
        widgetStations = []
        widgetStationsError = nil
        widgetStationsLoading = kind != .sea
        guard kind != .sea else { return }
        defer {
            if kind == settingsStore.widgetSupplementKind { widgetStationsLoading = false }
        }
        do {
            let choices: [WidgetStationChoice]
            if kind == .snow {
                let report = try await container.skiConditionsService.fetchReport()
                choices = report.locations.map { WidgetStationChoice(id: $0.id, name: $0.name) }
            } else {
                let snapshot = try await container.airQualityService.fetchLatestSnapshot(forceRefresh: true)
                choices = snapshot.stations.map { WidgetStationChoice(id: $0.code, name: $0.name) }
            }
            guard !Task.isCancelled, kind == settingsStore.widgetSupplementKind else { return }
            widgetStations = choices.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            if choices.isEmpty { widgetStationsError = "ARSO trenutno ne objavlja seznama postaj." }
        } catch {
            guard !Task.isCancelled, kind == settingsStore.widgetSupplementKind else { return }
            widgetStationsError = "Postaj ni bilo mogoče naložiti. Shranjena izbira ostane veljavna."
        }
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


private struct WidgetStationChoice: Identifiable {
    let id: String
    let name: String
}
