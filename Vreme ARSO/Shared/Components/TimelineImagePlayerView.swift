import Combine
import SwiftUI

protocol TimelineFrameRepresentable: Identifiable {
    var timestamp: Date? { get }
    var imageURL: URL { get }
    var geoReference: FrameGeoReference? { get }
}

extension RadarFrame: TimelineFrameRepresentable {}
extension GraphicFrame: TimelineFrameRepresentable {}

struct TimelineImagePlayerView<Frame: TimelineFrameRepresentable>: View {
    let title: String
    let frames: [Frame]
    let cache: ImageCacheService

    @State private var selectedIndex = 0
    @State private var isPlaying = false

    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    private var frameURLs: [URL] { frames.map(\.imageURL) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let frame = frames[safe: selectedIndex] {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))

                        RemoteCachedImage(url: frame.imageURL, cache: cache)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                        if let geoReference = frame.geoReference {
                            SloveniaOutlineOverlay(geoReference: geoReference)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .allowsHitTesting(false)
                        }
                    }
                    .aspectRatio(frame.geoReference?.aspectRatio ?? (4 / 3), contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    if frame.geoReference != nil {
                        Label("Obris Slovenije pomaga pri orientaciji prikaza.", systemImage: "map")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ContentUnavailableView("Ni slik", systemImage: "photo.on.rectangle")
                }

                HStack {
                    Button {
                        isPlaying.toggle()
                    } label: {
                        Label(isPlaying ? "Premor" : "Predvajaj", systemImage: isPlaying ? "pause.fill" : "play.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    if let frame = frames[safe: selectedIndex] {
                        Spacer()
                        Text(frame.timestamp.map(DateFormatterSI.displayTime.string(from:)) ?? "Brez časa")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if !frames.isEmpty {
                    Slider(
                        value: Binding(
                            get: { Double(selectedIndex) },
                            set: { selectedIndex = Int($0.rounded()) }
                        ),
                        in: 0...Double(max(frames.count - 1, 0)),
                        step: 1
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onReceive(timer) { _ in
            guard isPlaying, !frames.isEmpty else { return }
            selectedIndex = (selectedIndex + 1) % frames.count
        }
        .task(id: frameURLs.map(\.absoluteString).joined(separator: "|")) {
            await preloadFrames(around: selectedIndex)

            let prioritized = prioritizedURLs(around: selectedIndex)
            let remaining = frameURLs.filter { !prioritized.contains($0) }
            await cache.preload(urls: remaining)
        }
        .onChange(of: selectedIndex) { _, newValue in
            Task {
                await preloadFrames(around: newValue)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicators(.hidden)
    }

    private func preloadFrames(around index: Int) async {
        await cache.preload(urls: prioritizedURLs(around: index))
    }

    private func prioritizedURLs(around index: Int) -> [URL] {
        guard !frameURLs.isEmpty else { return [] }

        let offsets = [0, 1, 2, 3, -1]
        var seen = Set<URL>()

        return offsets.compactMap { offset in
            let normalized = (index + offset + frameURLs.count) % frameURLs.count
            let url = frameURLs[normalized]
            return seen.insert(url).inserted ? url : nil
        }
    }
}

private struct SloveniaOutlineOverlay: View {
    let geoReference: FrameGeoReference

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.05), Color.clear, Color.black.opacity(0.18)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                if let outline = sloveniaPath(in: geometry.size) {
                    outline
                        .stroke(Color.black.opacity(0.5), style: StrokeStyle(lineWidth: 4.4, lineJoin: .round))
                        .blur(radius: 1)

                    outline
                        .stroke(Color.white.opacity(0.92), style: StrokeStyle(lineWidth: 2.2, lineJoin: .round))
                        .shadow(color: Color.black.opacity(0.45), radius: 3, y: 1)
                }

                ForEach(SloveniaOverlayData.anchorCities) { city in
                    if let point = geoReference.normalizedPosition(latitude: city.latitude, longitude: city.longitude) {
                        CityAnchorLabel(name: city.name)
                            .position(
                                x: min(max(point.x * geometry.size.width, 54), geometry.size.width - 54),
                                y: min(max(point.y * geometry.size.height, 18), geometry.size.height - 18)
                            )
                    }
                }
            }
        }
    }

    private func sloveniaPath(in size: CGSize) -> Path? {
        let projected = SloveniaOverlayData.border.compactMap { point in
            geoReference.normalizedPosition(latitude: point.latitude, longitude: point.longitude)
        }

        guard projected.count > 2 else { return nil }

        return Path { path in
            let first = projected[0]
            path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))

            for point in projected.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
            }
        }
    }
}

private struct CityAnchorLabel: View {
    let name: String

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .overlay {
                    Circle()
                        .stroke(Color.black.opacity(0.5), lineWidth: 1)
                }

            Text(name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.72), in: Capsule())
        }
        .shadow(color: Color.black.opacity(0.28), radius: 5, y: 2)
    }
}
