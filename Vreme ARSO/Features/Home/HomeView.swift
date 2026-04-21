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
            contentView
                .navigationTitle("Vreme")
                .navigationBarTitleDisplayMode(.inline)
                .animation(.easeInOut(duration: 0.22), value: viewModel.state?.location.displayName)
                .task {
                    locationService.requestAccessIfNeeded()
                    _ = viewModel.restorePersistedStateIfAvailable()

                    if settingsStore.autoRefreshEnabled || viewModel.state == nil {
                        await refreshHome(forceLocationRefresh: true)
                    }
                }
                .onChange(of: settingsStore.homeLocationPreferenceKey) { _, _ in
                    reloadHome()
                }
                .onChange(of: settingsStore.favoriteStationIDs) { _, _ in
                    reloadHome()
                }
                .onChange(of: settingsStore.autoRefreshEnabled) { _, isEnabled in
                    guard isEnabled else { return }
                    reloadHome()
                }
                .onChange(of: currentLocationSignature) { _, _ in
                    guard settingsStore.useCurrentLocation, settingsStore.autoRefreshEnabled else { return }
                    reloadHome()
                }
                .appScreenBackground()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.state == nil {
            HomeSkeletonView()
        } else if let state = viewModel.state {
            stateContent(state)
        } else if let errorMessage = viewModel.errorMessage {
            ErrorStateView(message: errorMessage) {
                reloadHome()
            }
        } else {
            ContentUnavailableView("Ni podatkov", systemImage: "icloud.slash")
        }
    }

    private func load() async {
        let currentLocation: CLLocation?
        currentLocation = settingsStore.useCurrentLocation ? locationService.currentLocation : nil

        await viewModel.load(
            settings: settingsStore,
            currentLocation: currentLocation
        )
    }

    private func refreshHome(forceLocationRefresh: Bool) async {
        let refreshedLocation: CLLocation?
        if settingsStore.useCurrentLocation, forceLocationRefresh {
            refreshedLocation = await locationService.refreshLocationAndWait()
        } else {
            refreshedLocation = settingsStore.useCurrentLocation ? locationService.currentLocation : nil
        }

        await viewModel.load(
            settings: settingsStore,
            currentLocation: refreshedLocation
        )
    }

    private func reloadHome() {
        Task { await load() }
    }

    private var currentLocationSignature: String {
        guard let coordinate = locationService.currentLocation?.coordinate else { return "" }
        return "\(coordinate.latitude),\(coordinate.longitude)"
    }

    private func stateContent(_ state: HomeViewModel.State) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroSection(state)
                metricsSection(state)
                forecastSection(state)

                if let warning = state.primaryWarning {
                    warningSection(warning)
                }

                imagerySection(state)
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .refreshable {
            await refreshHome(forceLocationRefresh: true)
        }
        .appScreenBackground()
    }

    private func heroSection(_ state: HomeViewModel.State) -> some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(state.location.displayName)
                        .font(.title2.weight(.semibold))

                    if let detailText = state.location.detailText {
                        Text(detailText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(NumberFormatterSI.string(from: state.observation.temperature, suffix: "°C"))
                        .font(.system(size: 68, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())

                    WeatherSymbolView(condition: state.condition, size: 34)
                        .padding(.bottom, 8)
                }

                Text(state.observation.weatherDescription ?? "Brez opisa")
                    .font(.title3.weight(.medium))

                HStack(spacing: 10) {
                    if let timestamp = state.observation.timestamp {
                        Label(DateFormatterSI.displayDateTime.string(from: timestamp), systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    SourceBadge()
                }

                if let staleNotice = state.staleNotice {
                    Label(staleNotice, systemImage: "clock.badge.exclamationmark")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.orange.opacity(0.12))
                        )
                }

                NavigationLink {
                    LocationForecastView(container: container, location: state.location)
                } label: {
                    Label("Napoved po dnevih", systemImage: "calendar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.Colors.accent.opacity(0.16))
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.Colors.cardGradient,
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.Colors.border.opacity(0.95), lineWidth: 1)
        }
        .shadow(color: AppTheme.Colors.accent.opacity(0.12), radius: 20, y: 9)
    }

    private func metricsSection(_ state: HomeViewModel.State) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            HeroMetricCard(
                title: "Veter",
                value: windText(state.observation),
                systemImage: "wind"
            )
            HeroMetricCard(
                title: "Padavine",
                value: NumberFormatterSI.string(from: state.observation.precipitation, suffix: "mm"),
                systemImage: "drop"
            )
            HeroMetricCard(
                title: "Vlaga",
                value: state.observation.humidity.map { "\($0) %" } ?? "Ni podatka",
                systemImage: "humidity"
            )
            HeroMetricCard(
                title: "Tlak",
                value: NumberFormatterSI.string(from: state.observation.pressure, suffix: "hPa"),
                systemImage: "gauge.with.dots.needle.33percent"
            )
        }
    }

    private func forecastSection(_ state: HomeViewModel.State) -> some View {
        CardSection(title: "Napoved", systemImage: "text.alignleft") {
            Text(state.summaryForecast?.body ?? "Napoved trenutno ni na voljo.")
                .font(.body)

            if let issuedAt = state.summaryForecast?.issuedAt {
                Text("Objavljeno: \(DateFormatterSI.displayDateTime.string(from: issuedAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            NavigationLink("Odpri tekstovno napoved") {
                ForecastTextView(container: container)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.top, 4)
        }
    }

    private func warningSection(_ warning: WarningItem) -> some View {
        NavigationLink {
            WarningsView(container: container)
        } label: {
            CardSection(title: "Opozorila", systemImage: "exclamationmark.triangle") {
                VStack(alignment: .leading, spacing: 8) {
                    Text(warning.title)
                        .font(.headline)
                        .foregroundStyle(warning.severity.color)

                    Text(warning.area)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(warning.body)
                        .font(.subheadline)
                        .lineLimit(3)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func imagerySection(_ state: HomeViewModel.State) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Grafične animacije")
                .font(.title3.weight(.semibold))

            NavigationLink {
                RadarView(container: container)
            } label: {
                ImageryPreviewCard(
                    title: "Radar padavin",
                    subtitle: state.radarPreview?.timestamp.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Zadnji prikaz",
                    imageURL: state.radarPreview?.imageURL,
                    cache: container.imageCacheService,
                    systemImage: "dot.radiowaves.left.and.right",
                    geoReference: state.radarPreview?.geoReference,
                    cropToSlovenia: true
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                SatelliteView(container: container)
            } label: {
                ImageryPreviewCard(
                    title: "Satelit",
                    subtitle: state.satellitePreview?.timestamp.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Zadnja slika",
                    imageURL: state.satellitePreview?.imageURL,
                    cache: container.imageCacheService,
                    systemImage: "globe.europe.africa",
                    geoReference: nil,
                    cropToSlovenia: false
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func windText(_ observation: CurrentObservation) -> String {
        let speed = NumberFormatterSI.string(from: observation.windSpeed, suffix: "m/s")
        if let direction = observation.windDirection {
            return "\(direction), \(speed)"
        }
        return speed
    }
}

private struct HeroMetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }
}

private struct ImageryPreviewCard: View {
    let title: String
    let subtitle: String
    let imageURL: URL?
    let cache: ImageCacheService
    let systemImage: String
    let geoReference: FrameGeoReference?
    let cropToSlovenia: Bool

    private var isRadarPreview: Bool {
        systemImage == "dot.radiowaves.left.and.right"
    }

    var body: some View {
        HStack(spacing: 14) {
            preview

            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: systemImage)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Odpri prikaz")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.Colors.accent)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.Colors.cardBackground)
        )
    }

    @ViewBuilder
    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isRadarPreview ? Color.black.opacity(0.12) : Color.secondary.opacity(0.08))

            Group {
                if let imageURL {
                    RemoteCachedImage(
                        url: imageURL,
                        cache: cache,
                        contentMode: .fill,
                        normalizedCropRect: cropRect
                    )
                } else {
                    Image(systemName: systemImage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 116, height: 84)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var cropRect: CGRect? {
        guard cropToSlovenia, let geoReference else { return nil }

        let borderRect = geoReference.normalizedBounds(for: SloveniaOverlayData.border)
        guard let borderRect else { return nil }

        let minX = max(0, borderRect.minX - 0.03)
        let minY = max(0, borderRect.minY - 0.03)
        let maxX = min(1, borderRect.maxX + 0.03)
        let maxY = min(1, borderRect.maxY + 0.06)

        return CGRect(
            x: minX,
            y: minY,
            width: max(maxX - minX, 0.001),
            height: max(maxY - minY, 0.001)
        )
    }
}

@MainActor
final class HomeViewModel: ObservableObject {
    struct State {
        let location: ResolvedForecastLocation
        let observation: CurrentObservation
        let condition: WeatherCondition
        let summaryForecast: ForecastTextSection?
        let primaryWarning: WarningItem?
        let radarPreview: RadarFrame?
        let satellitePreview: SatelliteFrame?
        let fetchedAt: Date

        var freshnessReferenceDate: Date {
            observation.timestamp ?? fetchedAt
        }

        var staleNotice: String? {
            guard Date().timeIntervalSince(freshnessReferenceDate) > 6 * 60 * 60 else { return nil }
            return "Podatki so starejši od 6 ur. Zadnja posodobitev: \(DateFormatterSI.displayDateTime.string(from: freshnessReferenceDate))"
        }
    }

    @Published private(set) var state: State?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    @discardableResult
    func restorePersistedStateIfAvailable() -> Bool {
        guard let persistedState = HomeStateStore.load() else { return false }

        withAnimation(.easeInOut(duration: 0.22)) {
            state = persistedState
        }
        errorMessage = nil
        return true
    }

    func load(settings: SettingsStore, currentLocation: CLLocation?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let preference = LocationPreferenceSnapshot(
                pinnedStationID: settings.pinnedFavoriteStationID,
                useCurrentLocation: settings.useCurrentLocation,
                selectedStationID: settings.selectedStationID,
                manualLocationName: settings.manualLocationName,
                manualCoordinate: settings.manualCoordinate
            )

            async let stationsTask = container.stationsService.fetchStations()
            async let observationsTask = container.currentWeatherService.fetchCurrentObservations()
            async let forecastTask = container.forecastTextService.fetchSections()
            async let warningsTask = container.warningsService.fetchWarnings()
            async let radarTask = container.radarService.fetchFrames()
            async let satelliteTask = container.satelliteService.fetchLatestFrame()

            let stations = try await stationsTask
            let observations = try await observationsTask
            let resolvedLocation = await container.locationResolver.resolve(
                preference: preference,
                currentLocation: currentLocation,
                stations: stations,
                observations: observations
            )

            guard let resolvedLocation else {
                throw ARSOError.parsingFailed("Za izbrano lokacijo trenutno ni vremenskih podatkov.")
            }

            let locationConditions = try? await container.locationForecastService.fetchCurrentConditions(for: resolvedLocation)
            let stationFallbackObservation = resolvedLocation.observation ?? observations.first
            let observation = mergedObservation(
                primary: locationConditions?.observation,
                fallback: stationFallbackObservation,
                fallbackStationID: resolvedLocation.nearestStation?.id ?? resolvedLocation.displayName
            )

            guard let observation else {
                throw ARSOError.parsingFailed("Za izbrano lokacijo trenutno ni vremenskih podatkov.")
            }

            let displayLocation = ResolvedForecastLocation(
                displayName: locationConditions?.locationName ?? resolvedLocation.displayName,
                detailText: resolvedLocation.detailText,
                source: resolvedLocation.source,
                coordinate: resolvedLocation.coordinate,
                nearestStation: resolvedLocation.nearestStation,
                observation: observation
            )

            let forecastSections = (try? await forecastTask) ?? []
            let warnings = (try? await warningsTask) ?? []
            let radarFrames = (try? await radarTask) ?? []
            let satelliteFrame = try? await satelliteTask
            let previewURLs = [radarFrames.last?.imageURL, radarFrames.first?.imageURL, satelliteFrame?.imageURL]
                .compactMap { $0 }

            let nextState = State(
                location: displayLocation,
                observation: observation,
                condition: container.weatherIconProvider.condition(for: observation),
                summaryForecast: forecastSections.first(where: { $0.type == .napoved }),
                primaryWarning: warnings.sorted(by: { $0.severity > $1.severity }).first,
                radarPreview: radarFrames.last ?? radarFrames.first,
                satellitePreview: satelliteFrame,
                fetchedAt: Date()
            )

            withAnimation(.easeInOut(duration: 0.22)) {
                state = nextState
            }
            errorMessage = nil
            HomeStateStore.save(nextState)
            Task {
                await container.imageCacheService.preload(urls: previewURLs)
            }
        } catch {
            if state == nil {
                let restored = restorePersistedStateIfAvailable()
                errorMessage = restored ? nil : error.localizedDescription
            } else {
                errorMessage = nil
            }
        }
    }

    private func mergedObservation(
        primary: CurrentObservation?,
        fallback: CurrentObservation?,
        fallbackStationID: String
    ) -> CurrentObservation? {
        guard primary != nil || fallback != nil else { return nil }

        return CurrentObservation(
            stationID: primary?.stationID ?? fallback?.stationID ?? fallbackStationID,
            timestamp: primary?.timestamp ?? fallback?.timestamp,
            temperature: primary?.temperature ?? fallback?.temperature,
            apparentTemperature: primary?.apparentTemperature ?? fallback?.apparentTemperature,
            humidity: primary?.humidity ?? fallback?.humidity,
            pressure: primary?.pressure ?? fallback?.pressure,
            windSpeed: primary?.windSpeed ?? fallback?.windSpeed,
            windGust: primary?.windGust ?? fallback?.windGust,
            windDirection: primary?.windDirection ?? fallback?.windDirection,
            windDirectionDegrees: primary?.windDirectionDegrees ?? fallback?.windDirectionDegrees,
            precipitation: primary?.precipitation ?? fallback?.precipitation,
            cloudiness: primary?.cloudiness ?? fallback?.cloudiness,
            weatherSymbol: primary?.weatherSymbol ?? fallback?.weatherSymbol,
            weatherDescription: primary?.weatherDescription ?? fallback?.weatherDescription,
            visibilityKilometers: primary?.visibilityKilometers ?? fallback?.visibilityKilometers,
            source: primary?.source ?? fallback?.source ?? "ARSO"
        )
    }
}

private enum HomeStateStore {
    private static let defaults = UserDefaults.standard
    private static let key = "cachedHomeState"

    static func load() -> HomeViewModel.State? {
        guard
            let data = defaults.data(forKey: key),
            let cachedState = try? JSONDecoder().decode(CachedHomeState.self, from: data)
        else {
            return nil
        }

        return cachedState.state
    }

    static func save(_ state: HomeViewModel.State) {
        guard let data = try? JSONEncoder().encode(CachedHomeState(state: state)) else { return }
        defaults.set(data, forKey: key)
    }
}

private struct CachedHomeState: Codable {
    let location: CachedResolvedForecastLocation
    let observation: CachedCurrentObservation
    let condition: String
    let summaryForecast: CachedForecastTextSection?
    let primaryWarning: CachedWarningItem?
    let radarPreview: CachedRadarFrame?
    let satellitePreview: CachedSatelliteFrame?
    let fetchedAt: Date

    init(state: HomeViewModel.State) {
        location = CachedResolvedForecastLocation(location: state.location)
        observation = CachedCurrentObservation(observation: state.observation)
        condition = state.condition.rawValue
        summaryForecast = state.summaryForecast.map(CachedForecastTextSection.init)
        primaryWarning = state.primaryWarning.map(CachedWarningItem.init)
        radarPreview = state.radarPreview.map(CachedRadarFrame.init)
        satellitePreview = state.satellitePreview.map(CachedSatelliteFrame.init)
        fetchedAt = state.fetchedAt
    }

    var state: HomeViewModel.State {
        let restoredObservation = observation.observation

        return HomeViewModel.State(
            location: location.location(observation: restoredObservation),
            observation: restoredObservation,
            condition: WeatherCondition(rawValue: condition) ?? .unknown,
            summaryForecast: summaryForecast?.section,
            primaryWarning: primaryWarning?.warning,
            radarPreview: radarPreview?.frame,
            satellitePreview: satellitePreview?.frame,
            fetchedAt: fetchedAt
        )
    }
}

private struct CachedResolvedForecastLocation: Codable {
    let displayName: String
    let detailText: String?
    let source: String
    let latitude: Double?
    let longitude: Double?
    let nearestStation: WeatherStation?

    init(location: ResolvedForecastLocation) {
        displayName = location.displayName
        detailText = location.detailText
        source = location.source.rawValue
        latitude = location.coordinate?.latitude
        longitude = location.coordinate?.longitude
        nearestStation = location.nearestStation
    }

    func location(observation: CurrentObservation) -> ResolvedForecastLocation {
        ResolvedForecastLocation(
            displayName: displayName,
            detailText: detailText,
            source: ForecastLocationSource(rawValue: source) ?? .manualPlace,
            coordinate: coordinate,
            nearestStation: nearestStation,
            observation: observation
        )
    }

    private var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private struct CachedCurrentObservation: Codable {
    let stationID: String
    let timestamp: Date?
    let temperature: Double?
    let apparentTemperature: Double?
    let humidity: Int?
    let pressure: Double?
    let windSpeed: Double?
    let windGust: Double?
    let windDirection: String?
    let windDirectionDegrees: Double?
    let precipitation: Double?
    let cloudiness: String?
    let weatherSymbol: String?
    let weatherDescription: String?
    let visibilityKilometers: Double?
    let source: String

    init(observation: CurrentObservation) {
        stationID = observation.stationID
        timestamp = observation.timestamp
        temperature = observation.temperature
        apparentTemperature = observation.apparentTemperature
        humidity = observation.humidity
        pressure = observation.pressure
        windSpeed = observation.windSpeed
        windGust = observation.windGust
        windDirection = observation.windDirection
        windDirectionDegrees = observation.windDirectionDegrees
        precipitation = observation.precipitation
        cloudiness = observation.cloudiness
        weatherSymbol = observation.weatherSymbol
        weatherDescription = observation.weatherDescription
        visibilityKilometers = observation.visibilityKilometers
        source = observation.source
    }

    var observation: CurrentObservation {
        CurrentObservation(
            stationID: stationID,
            timestamp: timestamp,
            temperature: temperature,
            apparentTemperature: apparentTemperature,
            humidity: humidity,
            pressure: pressure,
            windSpeed: windSpeed,
            windGust: windGust,
            windDirection: windDirection,
            windDirectionDegrees: windDirectionDegrees,
            precipitation: precipitation,
            cloudiness: cloudiness,
            weatherSymbol: weatherSymbol,
            weatherDescription: weatherDescription,
            visibilityKilometers: visibilityKilometers,
            source: source
        )
    }
}

private struct CachedForecastTextSection: Codable {
    let id: String
    let type: String
    let title: String
    let body: String
    let issuedAt: Date?
    let sourceURL: String

    init(section: ForecastTextSection) {
        id = section.id
        type = section.type.rawValue
        title = section.title
        body = section.body
        issuedAt = section.issuedAt
        sourceURL = section.sourceURL.absoluteString
    }

    var section: ForecastTextSection {
        ForecastTextSection(
            id: id,
            type: ForecastTextSectionType(rawValue: type) ?? .napoved,
            title: title,
            body: body,
            issuedAt: issuedAt,
            sourceURL: URL(string: sourceURL) ?? Endpoint.forecastTextOverview.url
        )
    }
}

private struct CachedWarningItem: Codable {
    let id: String
    let title: String
    let severity: String
    let area: String
    let validFrom: Date?
    let validTo: Date?
    let body: String
    let eventType: String

    init(warning: WarningItem) {
        id = warning.id
        title = warning.title
        severity = warning.severity.rawValue
        area = warning.area
        validFrom = warning.validFrom
        validTo = warning.validTo
        body = warning.body
        eventType = warning.eventType
    }

    var warning: WarningItem {
        WarningItem(
            id: id,
            title: title,
            severity: WarningSeverity(rawValue: severity) ?? .unknown,
            area: area,
            validFrom: validFrom,
            validTo: validTo,
            body: body,
            eventType: eventType,
            polygons: []
        )
    }
}

private struct CachedRadarFrame: Codable {
    let id: String
    let timestamp: Date?
    let imageURL: String

    init(frame: RadarFrame) {
        id = frame.id
        timestamp = frame.timestamp
        imageURL = frame.imageURL.absoluteString
    }

    var frame: RadarFrame? {
        guard let url = URL(string: imageURL) else { return nil }

        return RadarFrame(
            id: id,
            timestamp: timestamp,
            imageURL: url,
            cachedLocalPath: nil,
            geoReference: nil
        )
    }
}

private struct CachedSatelliteFrame: Codable {
    let id: String
    let timestamp: Date?
    let imageURL: String
    let animationURL: String?

    init(frame: SatelliteFrame) {
        id = frame.id
        timestamp = frame.timestamp
        imageURL = frame.imageURL.absoluteString
        animationURL = frame.animationURL?.absoluteString
    }

    var frame: SatelliteFrame? {
        guard let url = URL(string: imageURL) else { return nil }

        return SatelliteFrame(
            id: id,
            timestamp: timestamp,
            imageURL: url,
            animationURL: animationURL.flatMap(URL.init(string:)),
            cachedLocalPath: nil
        )
    }
}

#Preview {
    HomeView(container: .live, settingsStore: SettingsStore(), locationService: LocationService())
}
