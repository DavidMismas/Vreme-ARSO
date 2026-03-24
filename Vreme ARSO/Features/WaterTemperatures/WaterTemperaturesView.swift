import Combine
import SwiftUI

struct WaterTemperaturesView: View {
    let container: AppContainer
    @StateObject private var viewModel: WaterTemperaturesViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: WaterTemperaturesViewModel(container: container))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.report == nil {
                LoadingStateView(title: "Nalagam temperature voda …")
            } else if let errorMessage = viewModel.errorMessage, viewModel.report == nil {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else if let report = viewModel.report, report.hasRenderableContent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let current = report.slots.first {
                            CardSection(title: "Morje", systemImage: "water.waves") {
                                HStack(alignment: .firstTextBaseline, spacing: 12) {
                                    Text(current.seaTemperature)
                                        .font(.system(size: 52, weight: .bold, design: .rounded))

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(current.label)
                                            .font(.headline)
                                        if let seaState = current.seaState {
                                            Text("Stanje morja: \(seaState)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        if let windSpeed = current.windSpeed {
                                            Text("Veter: \(windSpeed)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }

                                SourceBadge()
                            }
                        }

                        if let statusMessage = report.statusMessage {
                            CardSection(title: "Reke in jezera", systemImage: "drop.triangle") {
                                Text("ARSO trenutno objavlja samo temperaturo morja. Podatki za reke in jezera so začasno nedosegljivi.")
                                    .font(.body)
                                Text(statusMessage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Morje še vedno prikazujemo iz stabilnega obalnega ARSO vira.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !report.slots.isEmpty {
                            CardSection(title: "Prihajajoči termini", systemImage: "calendar") {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(report.slots) { slot in
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(slot.label)
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                                Text(slot.seaTemperature)
                                                    .font(.title3.weight(.semibold))
                                                if let seaState = slot.seaState {
                                                    Text("Morje \(seaState)")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                if let windSpeed = slot.windSpeed {
                                                    Text(windSpeed)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(14)
                                            .frame(width: 132, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                    .fill(AppTheme.Colors.groupedBackground)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Temperature voda")
                .refreshable {
                    await viewModel.load()
                }
                .appScreenBackground()
            } else {
                ContentUnavailableView(
                    "Temperature voda niso na voljo",
                    systemImage: "water.waves",
                    description: Text("ARSO trenutno objavlja samo temperaturo morja. Podatki za reke in jezera so začasno nedosegljivi.")
                )
            }
        }
        .navigationTitle("Temperature voda")
        .task {
            await viewModel.load()
        }
        .appScreenBackground()
    }
}

private extension WaterTemperatureReport {
    var hasRenderableContent: Bool {
        !slots.isEmpty || statusMessage?.nilIfBlank != nil
    }
}

@MainActor
final class WaterTemperaturesViewModel: ObservableObject {
    @Published private(set) var report: WaterTemperatureReport?
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
            report = try await container.waterTemperaturesService.fetchReport()
            errorMessage = nil
        } catch {
            report = nil
            errorMessage = error.localizedDescription
        }
    }
}
