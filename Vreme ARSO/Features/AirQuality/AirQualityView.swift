import Charts
import Combine
import MapKit
import SwiftUI

struct AirQualityView: View {
    let container: AppContainer
    @StateObject private var viewModel: AirQualityViewModel
    @State private var selectedStation: AirQualityStationItem?
    @State private var isShowingInfo = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.15, longitude: 14.95),
            span: MKCoordinateSpan(latitudeDelta: 2.3, longitudeDelta: 2.4)
        )
    )

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: AirQualityViewModel(container: container))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.stations.isEmpty {
                LoadingStateView(title: "Nalagam čistost zraka …")
            } else if let errorMessage = viewModel.errorMessage, viewModel.stations.isEmpty {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.retry() }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        headerCard
                        mapCard
                        AirQualityLegendView()
                        stationList
                    }
                    .padding()
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("Čistost zraka")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isShowingInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("Pomen meritev")

                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Osveži")
            }
        }
        .sheet(isPresented: $isShowingInfo) {
            AirQualityInfoSheet()
        }
        .sheet(item: $selectedStation) { item in
            AirQualityStationDetailSheet(item: item, service: container.airQualityService)
                .presentationDetents([.medium, .large])
        }
        .task {
            await viewModel.loadIfNeeded()
        }
        .appScreenBackground()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentSecondary.opacity(0.18))
                        .frame(width: 46, height: 46)

                    Image(systemName: "aqi.medium")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accentSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Zadnje urne meritve")
                        .font(.title3.weight(.semibold))
                    Text("PM2.5 ima prednost pri oceni; če manjka, uporabimo PM10.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                statusPill(
                    title: "Postaje",
                    value: "\(viewModel.stations.count)",
                    systemImage: "sensor.tag.radiowaves.forward"
                )
                statusPill(
                    title: "Posodobljeno",
                    value: viewModel.lastUpdated.map { DateFormatterSI.displayTime.string(from: $0) } ?? "Ni podatkov",
                    systemImage: "clock"
                )
            }

            if let statusMessage = viewModel.statusMessage {
                Text(statusMessage)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.Colors.accentSecondary)
            }

            SourceBadge()
        }
        .padding(16)
        .appCardSurface()
    }

    private func statusPill(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.accent)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.groupedBackground.opacity(0.65), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Merilne postaje", systemImage: "map")
                    .font(.headline)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Map(position: $cameraPosition, interactionModes: .all) {
                ForEach(viewModel.stations) { item in
                    Annotation(item.station.name, coordinate: item.station.coordinate, anchor: .bottom) {
                        Button {
                            selectedStation = item
                        } label: {
                            AirQualityStationMarkerView(level: item.level)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapStyle(.standard)
            .frame(height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.Colors.border.opacity(0.55), lineWidth: 1)
            }
        }
        .padding(16)
        .appCardSurface()
    }

    private var stationList: some View {
        CardSection(title: "Postaje", systemImage: "list.bullet") {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.stations) { item in
                    Button {
                        selectedStation = item
                    } label: {
                        AirQualityStationRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct AirQualityStationRow: View {
    let item: AirQualityStationItem

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.level.color)
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.station.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(item.level.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(AirQualityFormat.concentration(item.primaryValue))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(item.primaryMetricLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(AppTheme.Colors.groupedBackground.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct AirQualityStationMarkerView: View {
    let level: AirQualityLevel

    var body: some View {
        ZStack {
            Circle()
                .fill(level.color)
                .frame(width: 24, height: 24)
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.22), radius: 4, y: 2)

            Circle()
                .fill(.white.opacity(0.92))
                .frame(width: 7, height: 7)
        }
        .padding(5)
        .background(.ultraThinMaterial, in: Circle())
    }
}

private struct AirQualityLegendView: View {
    private let levels: [AirQualityLevel] = [
        .good,
        .moderate,
        .unhealthySensitive,
        .unhealthy,
        .veryUnhealthy,
        .noData
    ]
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        CardSection(title: "Legenda barv", systemImage: "circle.hexagongrid.fill") {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(levels, id: \.self) { level in
                    HStack(spacing: 7) {
                        Circle()
                            .fill(level.color)
                            .frame(width: 9, height: 9)

                        Text(level.title)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(level == .unhealthySensitive ? 2 : 1)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(AppTheme.Colors.groupedBackground.opacity(0.65), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

private struct AirQualityStationDetailSheet: View {
    @StateObject private var viewModel: AirQualityStationDetailViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    init(item: AirQualityStationItem, service: ARSOAirQualityService) {
        _viewModel = StateObject(wrappedValue: AirQualityStationDetailViewModel(item: item, service: service))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    badge
                    updatedCard
                    metricsGrid
                    chartSection
                }
                .padding()
            }
            .navigationTitle(viewModel.stationName)
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadChartIfNeeded()
            }
            .appScreenBackground()
        }
    }

    private var badge: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.badgeTitle)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text(viewModel.badgeValue)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.94))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(viewModel.level.color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var updatedCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Zadnja posodobitev")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(viewModel.lastUpdate)
                .font(.body.weight(.medium))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardSurface(cornerRadius: 16)
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.metrics) { metric in
                VStack(alignment: .leading, spacing: 6) {
                    Text(metric.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(metric.value)
                        .font(.body.weight(.semibold))
                        .minimumScaleFactor(0.78)
                        .lineLimit(2)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.Colors.groupedBackground.opacity(0.72), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Trend kakovosti zraka")
                    .font(.headline)
                Spacer()
                if viewModel.isChartLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Picker("Obdobje", selection: $viewModel.selectedRange) {
                ForEach(AirQualityStationDetailViewModel.ChartRange.allCases) { range in
                    Text(range.title).tag(range)
                }
            }
            .pickerStyle(.segmented)

            if !viewModel.chartPoints.isEmpty {
                Chart(viewModel.chartPoints) { point in
                    LineMark(
                        x: .value("Čas", point.date),
                        y: .value("Koncentracija", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(viewModel.level.color)

                    AreaMark(
                        x: .value("Čas", point.date),
                        y: .value("Koncentracija", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(viewModel.level.color.opacity(0.18))
                }
                .frame(height: 190)
                .chartYScale(domain: 0 ... viewModel.chartUpperBound)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: viewModel.selectedRange.desiredTickCount)) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: viewModel.selectedRange.axisFormat)
                    }
                }
            } else if viewModel.isChartLoading {
                ProgressView("Nalagam graf …")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                Text(viewModel.chartMessage ?? "Ni podatkov za izbrano obdobje.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }

            HStack {
                Text("Prikaz: PM2.5, če manjka PM10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    Task { await viewModel.refreshChart(forceRefresh: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Osveži graf")
                .buttonStyle(.bordered)
            }
        }
        .padding(14)
        .appCardSurface(cornerRadius: 16)
    }
}

private struct AirQualityInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(pollutants) { pollutant in
                        pollutantCard(pollutant)
                    }
                }
                .padding()
            }
            .navigationTitle("Pomen meritev")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zapri") {
                        dismiss()
                    }
                }
            }
            .appScreenBackground()
        }
    }

    private func pollutantCard(_ pollutant: PollutantInfo) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(pollutant.title)
                .font(.headline)
            Text(pollutant.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Pragovi")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                ForEach(pollutant.ranges) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.level.color)
                            .frame(width: 10, height: 10)

                        Text("\(item.interval): \(item.label)")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(item.level.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            if let source = pollutant.source {
                infoLine(title: "Vir", value: source)
            }

            infoLine(title: "Vpliv", value: pollutant.impact)
        }
        .padding(14)
        .appCardSurface(cornerRadius: 16)
    }

    private func infoLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
        }
    }

    private var pollutants: [PollutantInfo] {
        [
            PollutantInfo(
                title: "PM2.5 - fini delci",
                description: "Zelo majhni delci, ki prodrejo globoko v pljuča in kri.",
                ranges: [
                    PollutantRange(interval: "0-15 µg/m³", label: "dobro", level: .good),
                    PollutantRange(interval: "16-35 µg/m³", label: "zmerno", level: .moderate),
                    PollutantRange(interval: "36-55 µg/m³", label: "slabo za občutljive", level: .unhealthySensitive),
                    PollutantRange(interval: "56-100 µg/m³", label: "slabo", level: .unhealthy),
                    PollutantRange(interval: ">100 µg/m³", label: "zelo slabo", level: .veryUnhealthy)
                ],
                source: "promet, kurjenje lesa, industrija",
                impact: "dihala, srce in dolgoročno večje tveganje za bolezni"
            ),
            PollutantInfo(
                title: "PM10 - grobi delci",
                description: "Večji delci, ki dražijo dihala, manj prodorni kot PM2.5.",
                ranges: [
                    PollutantRange(interval: "0-25 µg/m³", label: "dobro", level: .good),
                    PollutantRange(interval: "26-50 µg/m³", label: "zmerno", level: .moderate),
                    PollutantRange(interval: "51-100 µg/m³", label: "slabo", level: .unhealthy),
                    PollutantRange(interval: ">100 µg/m³", label: "zelo slabo", level: .veryUnhealthy)
                ],
                source: "promet, prah, kurjenje",
                impact: "kašelj, draženje in poslabšanje astme"
            ),
            PollutantInfo(
                title: "NO₂ - dušikov dioksid",
                description: "Plin, močno povezan s prometom.",
                ranges: [
                    PollutantRange(interval: "0-40 µg/m³", label: "dobro", level: .good),
                    PollutantRange(interval: "41-100 µg/m³", label: "zmerno", level: .moderate),
                    PollutantRange(interval: "101-200 µg/m³", label: "slabo", level: .unhealthy),
                    PollutantRange(interval: ">200 µg/m³", label: "zelo slabo", level: .veryUnhealthy)
                ],
                source: nil,
                impact: "draženje dihal in slabše delovanje pljuč"
            ),
            PollutantInfo(
                title: "O₃ - ozon pri tleh",
                description: "Poleti pogost, nastaja ob soncu iz drugih onesnaževal.",
                ranges: [
                    PollutantRange(interval: "0-60 µg/m³", label: "dobro", level: .good),
                    PollutantRange(interval: "61-120 µg/m³", label: "zmerno", level: .moderate),
                    PollutantRange(interval: "121-180 µg/m³", label: "slabo", level: .unhealthy),
                    PollutantRange(interval: ">180 µg/m³", label: "zelo slabo", level: .veryUnhealthy)
                ],
                source: nil,
                impact: "draženje oči in dihal ter slabša telesna zmogljivost"
            ),
            PollutantInfo(
                title: "SO₂ - žveplov dioksid",
                description: "Redkejši, predvsem povezan z industrijo in kurilnimi gorivi.",
                ranges: [
                    PollutantRange(interval: "0-100 µg/m³", label: "dobro", level: .good),
                    PollutantRange(interval: "101-350 µg/m³", label: "slabo", level: .unhealthy),
                    PollutantRange(interval: ">350 µg/m³", label: "zelo slabo", level: .veryUnhealthy)
                ],
                source: nil,
                impact: "draženje dihal, posebej tvegano za astmatike"
            ),
            PollutantInfo(
                title: "CO - ogljikov monoksid",
                description: "Brezbarven plin brez vonja, nevaren pri visokih koncentracijah.",
                ranges: [
                    PollutantRange(interval: "0-5 mg/m³", label: "normalno", level: .good),
                    PollutantRange(interval: "5-10 mg/m³", label: "povišano", level: .moderate),
                    PollutantRange(interval: ">10 mg/m³", label: "nevarno", level: .veryUnhealthy)
                ],
                source: nil,
                impact: "zmanjšan dovod kisika v telo"
            )
        ]
    }
}

@MainActor
final class AirQualityViewModel: ObservableObject {
    @Published private(set) var stations: [AirQualityStationItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var statusMessage: String?
    @Published private(set) var lastUpdated: Date?

    private let container: AppContainer
    private var didLoad = false

    init(container: AppContainer) {
        self.container = container
    }

    func loadIfNeeded() async {
        guard !didLoad else { return }
        didLoad = true
        await fetch(forceRefresh: false, showLoading: true)
    }

    func refresh() async {
        await fetch(forceRefresh: true, showLoading: stations.isEmpty)
    }

    func retry() async {
        await fetch(forceRefresh: true, showLoading: true)
    }

    private func fetch(forceRefresh: Bool, showLoading: Bool) async {
        if showLoading {
            isLoading = true
        }
        errorMessage = nil
        statusMessage = nil

        do {
            let snapshot = try await container.airQualityService.fetchLatestSnapshot(forceRefresh: forceRefresh)
            apply(snapshot)
        } catch {
            if let cached = await container.airQualityService.cachedSnapshot() {
                apply(cached)
                statusMessage = "Brez povezave: prikazujem zadnje shranjene ARSO podatke."
            } else {
                stations = []
                errorMessage = "Podatkov ARSO o zraku trenutno ni mogoče naložiti."
            }
        }

        isLoading = false
    }

    private func apply(_ snapshot: AirQualitySnapshot) {
        let mapped = snapshot.stations.map { station in
            AirQualityStationItem(
                station: station,
                measurement: snapshot.measurementsByStationCode[station.code]
            )
        }

        stations = mapped.sorted {
            $0.station.name.localizedCaseInsensitiveCompare($1.station.name) == .orderedAscending
        }
        lastUpdated = mapped.compactMap { $0.measurement?.lastUpdate }.max() ?? snapshot.fetchedAt
    }
}

@MainActor
final class AirQualityStationDetailViewModel: ObservableObject {
    struct Metric: Identifiable {
        let id = UUID()
        let title: String
        let value: String
    }

    enum ChartRange: String, CaseIterable, Identifiable {
        case last24Hours
        case last7Days

        var id: String { rawValue }

        var title: String {
            switch self {
            case .last24Hours:
                return "24 ur"
            case .last7Days:
                return "7 dni"
            }
        }

        var seconds: TimeInterval {
            switch self {
            case .last24Hours:
                return 24 * 60 * 60
            case .last7Days:
                return 7 * 24 * 60 * 60
            }
        }

        var desiredTickCount: Int {
            switch self {
            case .last24Hours:
                return 6
            case .last7Days:
                return 7
            }
        }

        var axisFormat: Date.FormatStyle {
            switch self {
            case .last24Hours:
                return .dateTime.hour(.twoDigits(amPM: .omitted))
            case .last7Days:
                return .dateTime.day().month(.abbreviated)
            }
        }
    }

    let item: AirQualityStationItem

    @Published var selectedRange: ChartRange = .last24Hours {
        didSet {
            applySelectedRange()
        }
    }
    @Published private(set) var chartPoints: [AirQualityChartPoint] = []
    @Published private(set) var isChartLoading = false
    @Published private(set) var chartMessage: String?

    private let service: ARSOAirQualityService
    private var allChartPoints: [AirQualityChartPoint] = []
    private var didLoadChart = false

    init(item: AirQualityStationItem, service: ARSOAirQualityService) {
        self.item = item
        self.service = service
    }

    var stationName: String {
        item.station.name
    }

    var level: AirQualityLevel {
        item.level
    }

    var badgeTitle: String {
        item.level.title
    }

    var badgeValue: String {
        guard let primaryValue = item.primaryValue else {
            return "Ni podatkov"
        }

        return "\(item.primaryMetricLabel) \(AirQualityFormat.rawValue(primaryValue)) µg/m³"
    }

    var lastUpdate: String {
        AirQualityFormat.dateTime(item.measurement?.lastUpdate)
    }

    var chartUpperBound: Double {
        let maxValue = chartPoints.map(\.value).max() ?? 10
        return max(maxValue * 1.15, 10)
    }

    var metrics: [Metric] {
        [
            Metric(title: "PM2.5", value: AirQualityFormat.concentration(item.measurement?.pm25)),
            Metric(title: "PM10", value: AirQualityFormat.concentration(item.measurement?.pm10)),
            Metric(title: "NO2", value: AirQualityFormat.concentration(item.measurement?.no2)),
            Metric(title: "O3", value: AirQualityFormat.concentration(item.measurement?.o3)),
            Metric(title: "SO2", value: AirQualityFormat.concentration(item.measurement?.so2)),
            Metric(title: "CO", value: AirQualityFormat.concentration(item.measurement?.co))
        ]
    }

    func loadChartIfNeeded() async {
        guard !didLoadChart else { return }
        didLoadChart = true
        await refreshChart(forceRefresh: false)
    }

    func refreshChart(forceRefresh: Bool) async {
        isChartLoading = true
        chartMessage = nil

        do {
            let measurements = try await service.fetchHistoricalMeasurements(
                for: item.station.code,
                forceRefresh: forceRefresh
            )

            allChartPoints = measurements.compactMap { measurement in
                guard let value = measurement.pm25 ?? measurement.pm10,
                      value >= 0,
                      let date = measurement.lastUpdate else {
                    return nil
                }

                return AirQualityChartPoint(date: date, value: value)
            }
            .sorted { $0.date < $1.date }

            applySelectedRange()
        } catch {
            allChartPoints = []
            chartPoints = []
            chartMessage = "Grafa trenutno ni mogoče naložiti."
        }

        isChartLoading = false
    }

    private func applySelectedRange() {
        guard !allChartPoints.isEmpty else {
            chartPoints = []
            chartMessage = chartMessage ?? "Ni podatkov za izbrano obdobje."
            return
        }

        let referenceDate = allChartPoints.last?.date ?? Date()
        let fromDate = referenceDate.addingTimeInterval(-selectedRange.seconds)
        let filtered = allChartPoints.filter { point in
            point.date >= fromDate && point.date <= referenceDate
        }

        chartPoints = filtered
        chartMessage = filtered.isEmpty ? "Ni podatkov za izbrano obdobje." : nil
    }
}

private enum AirQualityFormat {
    static func dateTime(_ date: Date?) -> String {
        guard let date else { return "Ni podatkov" }
        return DateFormatterSI.displayDateTime.string(from: date)
    }

    static func concentration(_ value: Double?) -> String {
        guard let value else { return "Ni podatkov" }
        return "\(rawValue(value)) µg/m³"
    }

    static func rawValue(_ value: Double?) -> String {
        guard let value else { return "Ni podatkov" }
        return NumberFormatterSI.decimal.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

private struct PollutantInfo: Identifiable {
    let title: String
    let description: String
    let ranges: [PollutantRange]
    let source: String?
    let impact: String

    var id: String { title }
}

private struct PollutantRange: Identifiable {
    let interval: String
    let label: String
    let level: AirQualityLevel

    var id: String { "\(interval)-\(label)" }
}
