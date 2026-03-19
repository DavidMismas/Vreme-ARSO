import Combine
import SwiftUI

struct MountainConditionsView: View {
    let container: AppContainer
    @StateObject private var viewModel: MountainConditionsViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: MountainConditionsViewModel(container: container))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.report == nil {
                LoadingStateView(title: "Nalagam razmere v gorah …")
            } else if let errorMessage = viewModel.errorMessage, viewModel.report == nil {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else if let report = viewModel.report, !report.locations.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(report.locations) { location in
                            MountainLocationCard(
                                location: location,
                                iconProvider: container.weatherIconProvider
                            )
                        }
                    }
                    .padding()
                }
                .navigationTitle("Razmere v gorah")
                .refreshable {
                    await viewModel.load()
                }
            } else {
                ContentUnavailableView(
                    "Razmere v gorah niso na voljo",
                    systemImage: "mountain.2",
                    description: Text("ARSO trenutno ne vrne uporabnega prikaza za ta sklop.")
                )
            }
        }
        .navigationTitle("Razmere v gorah")
        .task {
            await viewModel.load()
        }
    }
}

private struct MountainLocationCard: View {
    let location: MountainConditionLocation
    let iconProvider: WeatherIconProvider
    @State private var expanded = false

    var body: some View {
        CardSection(title: location.name, systemImage: "mountain.2") {
            if let issuedAtText = location.issuedAtText {
                Text(issuedAtText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let current = location.slots.first {
                MountainSlotSummary(
                    slot: current,
                    topElevation: location.topElevation,
                    bottomElevation: location.bottomElevation,
                    iconProvider: iconProvider
                )
            }

            if let next = location.slots.dropFirst().first {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Naslednji termin: \(next.label)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    MountainSlotCompact(slot: next, iconProvider: iconProvider)
                }
            }

            if location.slots.count > 2 {
                DisclosureGroup(isExpanded: $expanded) {
                    VStack(spacing: 10) {
                        ForEach(Array(location.slots.dropFirst(2))) { slot in
                            MountainSlotCompact(slot: slot, iconProvider: iconProvider)
                        }
                    }
                    .padding(.top, 8)
                } label: {
                    Text("Pokaži dodatne termine")
                        .font(.subheadline.weight(.semibold))
                }
            }

            SourceBadge()
        }
    }
}

private struct MountainSlotSummary: View {
    let slot: MountainConditionSlot
    let topElevation: String?
    let bottomElevation: String?
    let iconProvider: WeatherIconProvider

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(slot.label)
                .font(.headline)

            if let topTemperature = slot.topTemperature {
                conditionLine(
                    title: topElevation ?? "Na vrhu",
                    symbol: slot.topConditionSymbol,
                    temperature: topTemperature,
                    wind: slot.topWindSpeed
                )
            }

            if let bottomTemperature = slot.bottomTemperature {
                conditionLine(
                    title: bottomElevation ?? "Spodaj",
                    symbol: slot.bottomConditionSymbol,
                    temperature: bottomTemperature,
                    wind: slot.bottomWindSpeed
                )
            }
        }
    }

    private func conditionLine(title: String, symbol: String?, temperature: String, wind: String?) -> some View {
        HStack(spacing: 12) {
            WeatherSymbolView(condition: iconProvider.condition(forSymbol: symbol), size: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text("\(temperature)\(wind.map { " • veter \($0)" } ?? "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct MountainSlotCompact: View {
    let slot: MountainConditionSlot
    let iconProvider: WeatherIconProvider

    var body: some View {
        HStack {
            Text(slot.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .leading)

            if let topTemperature = slot.topTemperature {
                HStack(spacing: 6) {
                    WeatherSymbolView(condition: iconProvider.condition(forSymbol: slot.topConditionSymbol), size: 16)
                    Text("Vrh \(topTemperature)")
                        .font(.caption)
                }
            }

            if let bottomTemperature = slot.bottomTemperature {
                HStack(spacing: 6) {
                    WeatherSymbolView(condition: iconProvider.condition(forSymbol: slot.bottomConditionSymbol), size: 16)
                    Text("Spodaj \(bottomTemperature)")
                        .font(.caption)
                }
            }

            Spacer()
        }
    }
}

@MainActor
final class MountainConditionsViewModel: ObservableObject {
    @Published private(set) var report: MountainConditionsReport?
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
            report = try await container.mountainConditionsService.fetchReport()
            errorMessage = nil
        } catch {
            report = nil
            errorMessage = error.localizedDescription
        }
    }
}
