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
            } else if let frame = viewModel.frame, viewModel.hasRenderableContent {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        CardSection(title: "Zadnja slika", systemImage: "photo") {
                            RemoteCachedImage(url: frame.imageURL, cache: container.imageCacheService)
                                .frame(maxWidth: .infinity)
                                .frame(height: 320)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            Text("Čas: \(frame.timestamp.map(DateFormatterSI.displayDateTime.string(from:)) ?? "Ni podatka")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SourceBadge()
                        }

                        if let player = viewModel.player {
                            CardSection(title: "Animacija", systemImage: "play.rectangle") {
                                VideoPlayer(player: player)
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
                .refreshable {
                    await viewModel.load()
                }
                .onDisappear {
                    viewModel.pause()
                }
                .appScreenBackground()
            } else {
                ContentUnavailableView(
                    "Satelitski prikaz ni na voljo",
                    systemImage: "globe.europe.africa",
                    description: Text("ARSO trenutno ne vrne uporabnega satelitskega prikaza.")
                )
            }
        }
        .navigationTitle("Satelit")
        .task {
            await viewModel.load()
        }
        .appScreenBackground()
    }
}

@MainActor
final class SatelliteViewModel: ObservableObject {
    @Published private(set) var frame: SatelliteFrame?
    @Published private(set) var player: AVPlayer?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let container: AppContainer

    init(container: AppContainer) {
        self.container = container
    }

    var hasRenderableContent: Bool {
        frame != nil
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let nextFrame = try await container.satelliteService.fetchLatestFrame()
            frame = nextFrame

            if let animationURL = nextFrame.animationURL {
                let nextPlayer = AVPlayer(url: animationURL)
                nextPlayer.pause()
                player = nextPlayer
            } else {
                player = nil
            }
            errorMessage = nil
        } catch {
            frame = nil
            player = nil
            errorMessage = error.localizedDescription
        }
    }

    func pause() {
        player?.pause()
    }
}
