import Combine
import CoreLocation
import SwiftUI

struct HomeView: View {
    let container: AppContainer
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var locationService: LocationService
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Vreme")
                .navigationBarTitleDisplayMode(.inline)
                .animation(.easeInOut(duration: 0.22), value: viewModel.state?.location.displayName)
                .preference(key: WeatherAtmospherePreference.self, value: viewModel.state.map { WeatherAtmosphere($0.condition) })
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

    private func refreshHome() async {
        await viewModel.refresh(settings: settingsStore, locationService: locationService)
    }

    private func reloadHome() {
        Task { await refreshHome() }
    }

    private func stateContent(_ state: HomeViewModel.State) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                heroSection(state)
                metricsSection(state)
                if let seaTemperature = state.seaTemperature {
                    seaTemperatureSection(seaTemperature)
                }
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
            await refreshHome()
        }
        .appScreenBackground()
    }

    private func heroSection(_ state: HomeViewModel.State) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(state.location.displayName)
                        .font(.title2.weight(.bold))

                    if let detailText = state.location.detailText {
                        Text(detailText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 10)

                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accent.opacity(0.13))
                    Circle()
                        .stroke(AppTheme.Colors.accent.opacity(0.28), lineWidth: 1)
                    WeatherSymbolView(condition: state.condition, size: 34)
                }
                .frame(width: 68, height: 68)
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(NumberFormatterSI.string(from: state.observation.temperature, suffix: "°C"))
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }

                Text(state.observation.weatherDescription ?? "Brez opisa")
                    .font(.title3.weight(.medium))

                HStack(spacing: 8) {
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
                    HStack(spacing: 8) {
                        Label("Napoved po dnevih", systemImage: "calendar")
                        Image(systemName: "arrow.right")
                    }
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
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardSurface(cornerRadius: 28)
    }

    private func metricsSection(_ state: HomeViewModel.State) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            HeroMetricCard(
                title: "Veter",
                value: windText(state.observation),
                systemImage: "wind",
                tint: AppTheme.Colors.accent
            )
            HeroMetricCard(
                title: state.precipitation?.periodLabel ?? "Padavine",
                value: NumberFormatterSI.string(from: state.precipitation?.amountMillimeters, suffix: "mm"),
                systemImage: "drop.fill",
                tint: .cyan,
                subtitle: state.precipitation?.stationName
            )
            HeroMetricCard(
                title: "Vlaga",
                value: state.observation.humidity.map { "\($0) %" } ?? "Ni podatka",
                systemImage: "humidity.fill",
                tint: AppTheme.Colors.accentSecondary
            )
            HeroMetricCard(
                title: "Tlak",
                value: NumberFormatterSI.string(from: state.observation.pressure, suffix: "hPa"),
                systemImage: "gauge.with.dots.needle.33percent",
                tint: .orange
            )
        }
    }

    private func seaTemperatureSection(_ seaTemperature: HomeSeaTemperature) -> some View {
        NavigationLink {
            WaterTemperaturesView(container: container)
        } label: {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.14))
                        .frame(width: 50, height: 50)

                    Image(systemName: "water.waves")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.cyan)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Temperatura morja")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(seaTemperature.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        if let seaState = seaTemperature.seaState {
                            Label("Stanje \(seaState)", systemImage: "water.waves")
                        }
                        if let windSpeed = seaTemperature.windSpeed {
                            Label(windSpeed, systemImage: "wind")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 12)

                Text(seaTemperature.temperature)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .appCardSurface(cornerRadius: 22)
        }
        .buttonStyle(.plain)
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
    let tint: Color
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                Text(title)
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.semibold))

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            if let subtitle {
                Text("Postaja: \(subtitle)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
        .background(tint.opacity(0.075), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        }
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
        .appCardSurface(cornerRadius: 22)
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
        let precipitation: PrecipitationReading?
        let condition: WeatherCondition
        let summaryForecast: ForecastTextSection?
        let primaryWarning: WarningItem?
        let radarPreview: RadarFrame?
        let satellitePreview: SatelliteFrame?
        let seaTemperature: HomeSeaTemperature?
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
    private var isRefreshing = false
    private var pendingPreferenceRefresh = false
    private(set) var lastRefreshAttempt: Date?

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

    func refresh(settings: SettingsStore, locationService: LocationService) async {
        guard !isRefreshing else {
            pendingPreferenceRefresh = true
            return
        }
        isRefreshing = true
        lastRefreshAttempt = .now
        defer {
            isRefreshing = false
            if Task.isCancelled { lastRefreshAttempt = nil }
            if pendingPreferenceRefresh {
                pendingPreferenceRefresh = false
                Task { await self.refresh(settings: settings, locationService: locationService) }
            }
        }
        let location: CLLocation?
        if settings.useCurrentLocation && settings.pinnedFavoriteStationID == nil {
            location = await locationService.refreshLocationAndWait() ?? locationService.currentLocation
        } else {
            location = nil
        }
        guard !Task.isCancelled else { return }
        await load(settings: settings, currentLocation: location)
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
            async let waterTask = container.waterTemperaturesService.fetchReport()

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

            async let precipitationTask = try? container.precipitationService.reading(near: resolvedLocation)
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
            let waterReport = try? await waterTask
            let previewURLs = [radarFrames.last?.imageURL, radarFrames.first?.imageURL, satelliteFrame?.imageURL]
                .compactMap { $0 }

            let nextState = State(
                location: displayLocation,
                observation: observation,
                precipitation: await precipitationTask,
                condition: container.weatherIconProvider.condition(for: observation),
                summaryForecast: forecastSections.first(where: { $0.type == .napoved }),
                primaryWarning: warnings.sorted(by: { $0.severity > $1.severity }).first,
                radarPreview: radarFrames.last ?? radarFrames.first,
                satellitePreview: satelliteFrame,
                seaTemperature: waterReport?.slots.first.map(HomeSeaTemperature.init),
                fetchedAt: Date()
            )

            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.22)) {
                state = nextState
            }
            errorMessage = nil
            HomeStateStore.save(nextState)
            WidgetSharedStore.weatherDidRefresh()
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

struct HomeSeaTemperature: Codable, Hashable {
    let label: String
    let temperature: String
    let seaState: String?
    let windSpeed: String?

    init(slot: WaterTemperatureSlot) {
        label = slot.label
        temperature = slot.seaTemperature
        seaState = slot.seaState
        windSpeed = slot.windSpeed
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
    let precipitation: PrecipitationReading?
    let condition: String
    let summaryForecast: CachedForecastTextSection?
    let primaryWarning: CachedWarningItem?
    let radarPreview: CachedRadarFrame?
    let satellitePreview: CachedSatelliteFrame?
    let seaTemperature: HomeSeaTemperature?
    let fetchedAt: Date

    init(state: HomeViewModel.State) {
        location = CachedResolvedForecastLocation(location: state.location)
        observation = CachedCurrentObservation(observation: state.observation)
        precipitation = state.precipitation
        condition = state.condition.rawValue
        summaryForecast = state.summaryForecast.map(CachedForecastTextSection.init)
        primaryWarning = state.primaryWarning.map(CachedWarningItem.init)
        radarPreview = state.radarPreview.map(CachedRadarFrame.init)
        satellitePreview = state.satellitePreview.map(CachedSatelliteFrame.init)
        seaTemperature = state.seaTemperature
        fetchedAt = state.fetchedAt
    }

    var state: HomeViewModel.State {
        let restoredObservation = observation.observation

        return HomeViewModel.State(
            location: location.location(observation: restoredObservation),
            observation: restoredObservation,
            precipitation: precipitation,
            condition: WeatherCondition(rawValue: condition) ?? .unknown,
            summaryForecast: summaryForecast?.section,
            primaryWarning: primaryWarning?.warning,
            radarPreview: radarPreview?.frame,
            satellitePreview: satellitePreview?.frame,
            seaTemperature: seaTemperature,
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
    HomeView(container: .live, settingsStore: SettingsStore(), locationService: LocationService(), viewModel: HomeViewModel(container: .live))
}
