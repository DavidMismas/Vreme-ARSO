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
                            seaOverviewCard(current)
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

                        if let waterMapURL = report.waterMapURL {
                            CardSection(title: "Reke, jezera in morje", systemImage: "map") {
                                RemoteCachedImage(
                                    url: waterMapURL,
                                    cache: container.imageCacheService,
                                    contentMode: .fit
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(AppTheme.Colors.border.opacity(0.45), lineWidth: 1)
                                }

                                Text("Karta temperature voda se pri ARSO posodobi vsak dan do 13.15.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !report.slots.isEmpty {
                            seaForecastCard(report.slots)
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

    private func seaOverviewCard(_ current: WaterTemperatureSlot) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accent.opacity(0.16))
                        .frame(width: 52, height: 52)

                    Image(systemName: "water.waves")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Morje zdaj")
                        .font(.title3.weight(.semibold))
                    Text(current.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Text(current.seaTemperature)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.75)
            }

            HStack(spacing: 10) {
                if let seaState = current.seaState {
                    waterInfoPill(title: "Stanje", value: seaState, systemImage: "water.waves")
                }
                if let windSpeed = current.windSpeed {
                    waterInfoPill(title: "Veter", value: windSpeed, systemImage: "wind")
                }
            }

            SourceBadge()
        }
        .padding(16)
        .appCardSurface()
    }

    private func seaForecastCard(_ slots: [WaterTemperatureSlot]) -> some View {
        CardSection(title: "Napoved za morje", systemImage: "calendar.day.timeline.left") {
            VStack(spacing: 10) {
                ForEach(slots) { slot in
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(slot.label)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            HStack(spacing: 8) {
                                if let seaState = slot.seaState {
                                    Label("Stanje \(seaState)", systemImage: "water.waves")
                                }
                                if let windSpeed = slot.windSpeed {
                                    Label(windSpeed, systemImage: "wind")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        }

                        Spacer(minLength: 12)

                        Text(slot.seaTemperature)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(AppTheme.Colors.accent)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .background(AppTheme.Colors.groupedBackground.opacity(0.68), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    private func waterInfoPill(title: String, value: String, systemImage: String) -> some View {
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.groupedBackground.opacity(0.68), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private extension WaterTemperatureReport {
    var hasRenderableContent: Bool {
        !slots.isEmpty || statusMessage?.nilIfBlank != nil || waterMapURL != nil
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
