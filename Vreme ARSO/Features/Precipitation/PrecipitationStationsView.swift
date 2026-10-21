import Combine
import SwiftUI

struct PrecipitationStationsView: View {
    @StateObject private var viewModel: PrecipitationStationsViewModel
    @State private var searchText = ""

    init(container: AppContainer) {
        _viewModel = StateObject(wrappedValue: PrecipitationStationsViewModel(service: container.precipitationService))
    }

    private var visibleStations: [PrecipitationStationStatus] {
        guard !searchText.isEmpty else { return viewModel.stations }
        return viewModel.stations.filter { $0.name.localizedStandardContains(searchText) }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.stations.isEmpty {
                LoadingStateView(title: "Nalagam padavinske postaje …")
            } else if let errorMessage = viewModel.errorMessage, viewModel.stations.isEmpty {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        headerCard

                        if visibleStations.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        } else {
                            ForEach(visibleStations) { station in
                                stationCard(station)
                            }
                        }
                    }
                    .padding()
                }
                .refreshable { await viewModel.load() }
            }
        }
        .navigationTitle("Padavine po postajah")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Poišči postajo")
        .task { await viewModel.load() }
        .appScreenBackground()
    }

    private var headerCard: some View {
        CardSection(title: "Meritve padavin", systemImage: "drop.fill") {
            Text("Količina padavin velja od začetka zadnjega merilnega obdobja. Začetna ura in čas meritve sta prikazana pri vsaki postaji.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Meritve: \(viewModel.stations.filter { $0.reading != nil }.count) od \(viewModel.stations.count) postaj")
                .font(.subheadline.weight(.semibold))

            SourceBadge()
        }
    }

    private func stationCard(_ station: PrecipitationStationStatus) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "drop.fill")
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 5) {
                Text(station.name)
                    .font(.headline)

                if let reading = station.reading {
                    Text(reading.periodLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Meritev: \(DateFormatterSI.displayDateTime.string(from: reading.validAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Trenutno ni podatka o padavinah")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text(amountText(for: station.reading))
                .font(.headline)
                .foregroundStyle(station.reading == nil ? Color.secondary : Color.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardSurface()
    }

    private func amountText(for reading: PrecipitationReading?) -> String {
        guard let reading else { return "Ni podatka" }
        let amount = Self.amountFormatter.string(from: NSNumber(value: reading.amountMillimeters))
            ?? "\(reading.amountMillimeters)"
        return "\(amount) mm"
    }

    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}

@MainActor
final class PrecipitationStationsViewModel: ObservableObject {
    @Published private(set) var stations: [PrecipitationStationStatus] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: ARSOPrecipitationService

    init(service: ARSOPrecipitationService) {
        self.service = service
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            stations = try await service.stations().sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
