import AVKit
import Combine
import SwiftUI

struct SatelliteView: View {
    let container: AppContainer
    @StateObject private var viewModel: SatelliteViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = StateObject(wrappedValue: SatelliteViewModel(container: container))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.frame == nil {
                LoadingStateView(title: "Nalagam satelitsko sliko …")
            } else if let errorMessage = viewModel.errorMessage, viewModel.frame == nil {
                ErrorStateView(message: errorMessage) {
                    Task { await viewModel.load() }
                }
            } else if let frame = viewModel.frame {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CardSection(title: "Zadnja slika", systemImage: "photo") {
                            RemoteCachedImage(url: frame.imageURL, cache: container.imageCacheService)
                                .frame(maxHeight: 320)
                            Text("Čas: \(frame.timestamp.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Ni podatka")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SourceBadge()
                        }

                        if let animationURL = frame.animationURL {
                            CardSection(title: "Animacija", systemImage: "play.rectangle") {
                                VideoPlayer(player: AVPlayer(url: animationURL))
                                    .frame(height: 220)
                                Text("Če ARSO ne objavi serije posameznih frame-ov, aplikacija uporabi uradno animacijo MP4.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Satelit")
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

@MainActor
final class SatelliteViewModel: ObservableObject {
    @Published private(set) var frame: SatelliteFrame?
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
            frame = try await container.satelliteService.fetchLatestFrame()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
