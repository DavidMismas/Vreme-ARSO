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
                    cache: container.imageCacheService,
                    overlayConfiguration: GeoOverlayConfiguration(
                        referencePlaces: viewModel.referencePlaces,
                        cropToSlovenia: true,
                        caption: "ARSO referenčne postaje pomagajo pri orientaciji radarskega prikaza."
                    )
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
    @Published private(set) var referencePlaces: [GeoReferencePlace] = []
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
            if let stations = try? await container.stationsService.fetchStations() {
                referencePlaces = radarReferencePlaces(from: stations)
            } else {
                referencePlaces = radarFallbackPlaces
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func radarReferencePlaces(from stations: [WeatherStation]) -> [GeoReferencePlace] {
        let preferredStationIDs = [
            ("LJUBL-ANA_BEZIGRAD_", "Ljubljana"),
            ("MARIBOR_SLIVNICA_", "Maribor"),
            ("PORTOROZ_SECOVLJE_", "Portorož")
        ]

        return preferredStationIDs.compactMap { stationID, displayName in
            guard let station = stations.first(where: { $0.id == stationID }) else { return nil }

            return GeoReferencePlace(
                name: displayName,
                latitude: station.latitude,
                longitude: station.longitude,
                labelOffset: labelOffset(for: displayName)
            )
        }
    }

    private var radarFallbackPlaces: [GeoReferencePlace] {
        [
            GeoReferencePlace(name: "Ljubljana", latitude: 46.056946, longitude: 14.505751, labelOffset: labelOffset(for: "Ljubljana")),
            GeoReferencePlace(name: "Maribor", latitude: 46.554650, longitude: 15.645881, labelOffset: labelOffset(for: "Maribor")),
            GeoReferencePlace(name: "Portorož", latitude: 45.514290, longitude: 13.592060, labelOffset: labelOffset(for: "Portorož"))
        ]
    }

    private func labelOffset(for name: String) -> CGSize {
        switch name {
        case "Ljubljana":
            return CGSize(width: 0, height: 22)
        case "Maribor":
            return CGSize(width: -10, height: 20)
        case "Portorož", "Koper":
            return CGSize(width: 16, height: 16)
        default:
            return CGSize(width: 0, height: 20)
        }
    }
}
