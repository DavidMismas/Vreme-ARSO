import Combine
import SwiftUI

struct SkiConditionsView: View {
    let container: AppContainer
    @StateObject private var viewModel: SkiConditionsViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: SkiConditionsViewModel(container: container))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.report == nil {
                LoadingStateView(title: "Nalagam snežne postaje …")
            } else if let errorMessage = viewModel.errorMessage, viewModel.report == nil {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else if let report = viewModel.report, !report.locations.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CardSection(title: "Kaj prikazuje", systemImage: "info.circle") {
                            Text("To so ARSO snežne postaje ob smučiščih in v gorah. Prikaz ne vključuje odprtosti prog ali naprav.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        ForEach(report.locations) { location in
                            CardSection(title: location.name, systemImage: "snowflake") {
                                VStack(alignment: .leading, spacing: 12) {
                                    if let subtitle = location.subtitle {
                                        Text(subtitle)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    HStack(alignment: .top, spacing: 12) {
                                        WeatherSymbolView(
                                            condition: container.weatherIconProvider.condition(
                                                forSymbol: location.weatherSymbol,
                                                description: location.weatherDescription
                                            ),
                                            size: 24
                                        )

                                        VStack(alignment: .leading, spacing: 6) {
                                            if let snowDepth = location.snowDepthCentimeters {
                                                Text("Snežna odeja: \(snowDepth) cm")
                                                    .font(.headline)
                                            } else {
                                                Text("Snežna odeja: ni podatka")
                                                    .font(.headline)
                                            }

                                            if let newSnow = location.newSnowCentimeters {
                                                Text("Nov sneg: \(newSnow) cm")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }

                                            if let temperature = location.temperature {
                                                Text("Temperatura: \(NumberFormatterSI.string(from: temperature, suffix: "°C"))")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }

                                            if let description = location.weatherDescription?.nilIfBlank {
                                                Text(description)
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }

                                    if let updatedAt = location.updatedAt {
                                        Text("Posodobljeno: \(DateFormatterSI.displayDateTime.string(from: updatedAt))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    SourceBadge()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Sneg in smučišča")
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    await viewModel.load()
                }
                .appScreenBackground()
            } else {
                ContentUnavailableView(
                    "Snežne postaje niso na voljo",
                    systemImage: "snowflake",
                    description: Text("ARSO trenutno ne vrne uporabnih snežnih podatkov za ta sklop.")
                )
            }
        }
        .navigationTitle("Sneg in smučišča")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .appScreenBackground()
    }
}

@MainActor
final class SkiConditionsViewModel: ObservableObject {
    @Published private(set) var report: SkiConditionsReport?
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
            report = try await container.skiConditionsService.fetchReport()
            errorMessage = nil
        } catch {
            report = nil
            errorMessage = error.localizedDescription
        }
    }
}
