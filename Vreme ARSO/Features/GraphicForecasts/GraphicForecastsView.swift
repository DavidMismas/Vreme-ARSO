import Combine
import SwiftUI

struct GraphicForecastsView: View {
    let container: AppContainer
    @StateObject private var viewModel: GraphicForecastsViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: GraphicForecastsViewModel(container: container))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    LoadingStateView(title: "Nalagam grafične napovedi …")
                } else if let errorMessage = viewModel.errorMessage, viewModel.items.isEmpty {
                    ErrorStateView(message: errorMessage) {
                        Task { await viewModel.load() }
                    }
                } else {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            TimelineImagePlayerView(
                                title: item.title,
                                frames: item.frames,
                                cache: container.imageCacheService,
                                overlayConfiguration: .sloveniaFocused,
                                legend: item.kind.timelineLegend,
                                imageDisplayStyle: item.kind == .oblacnost ? .cloudiness : .default
                            )
                            .padding()
                        } label: {
                            GraphicForecastLinkRow(item: item)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Grafične napovedi")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.load()
        }
        .appScreenBackground()
    }
}

private struct GraphicForecastLinkRow: View {
    let item: GraphicForecastItem

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accent.opacity(0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: item.kind.systemImage)
                    .font(.headline)
                    .foregroundStyle(AppTheme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(item.kind.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text(item.updatedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.Colors.accent.opacity(0.9))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            AppTheme.Colors.cardGradient,
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.Colors.border.opacity(0.95), lineWidth: 1)
        }
        .shadow(color: AppTheme.Colors.accent.opacity(0.08), radius: 10, y: 4)
    }
}

private extension GraphicForecastItem {
    var updatedText: String {
        if let updatedAt {
            return "Posodobljeno: \(DateFormatterSI.displayDateTime.string(from: updatedAt))"
        }
        return "Čas osvežitve ni na voljo"
    }
}

private extension Endpoint.GraphicKind {
    var systemImage: String {
        switch self {
        case .temperatura:
            return "thermometer.medium"
        case .veter:
            return "wind"
        case .oblacnost:
            return "cloud"
        case .padavine:
            return "cloud.rain"
        case .radar:
            return "dot.radiowaves.left.and.right"
        case .toca:
            return "cloud.hail"
        }
    }

    var subtitle: String {
        switch self {
        case .temperatura:
            return "Barvni prikaz temperature po Sloveniji"
        case .veter:
            return "Hitrost vetra in smer gibanja"
        case .oblacnost:
            return "Prikaz oblakov nad Slovenijo"
        case .padavine:
            return "Napoved padavin po območjih"
        case .radar:
            return "Radarski odmev padavin v živo"
        case .toca:
            return "Ocena možnosti za pojav toče"
        }
    }
}

@MainActor
final class GraphicForecastsViewModel: ObservableObject {
    @Published private(set) var items: [GraphicForecastItem] = []
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
            items = try await container.graphicForecastService.fetchGraphicForecasts()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
