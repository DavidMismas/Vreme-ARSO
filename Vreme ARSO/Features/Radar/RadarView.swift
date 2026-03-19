import Combine
import SwiftUI

struct RadarView: View {
    let container: AppContainer
    @StateObject private var viewModel: RadarViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: RadarViewModel(container: container))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.frames.isEmpty {
                LoadingStateView(title: "Nalagam radar …")
            } else if let errorMessage = viewModel.errorMessage, viewModel.frames.isEmpty {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else {
                TimelineImagePlayerView(
                    title: "Radar",
                    frames: viewModel.frames,
                    cache: container.imageCacheService
                )
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                SourceBadge()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

@MainActor
final class RadarViewModel: ObservableObject {
    @Published private(set) var frames: [RadarFrame] = []
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
            frames = try await container.radarService.fetchFrames()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
