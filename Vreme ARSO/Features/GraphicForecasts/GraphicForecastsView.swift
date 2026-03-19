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
        List {
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
                            cache: container.imageCacheService
                        )
                        .padding()
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.headline)
                            Text("Posodobljeno: \(item.updatedAt.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Ni podatka")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Grafične napovedi")
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.load()
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
