import Combine
import SwiftUI

protocol TimelineFrameRepresentable: Identifiable {
    var timestamp: Date? { get }
    var imageURL: URL { get }
    var geoReference: FrameGeoReference? { get }
}

extension RadarFrame: TimelineFrameRepresentable {}
extension GraphicFrame: TimelineFrameRepresentable {}

struct GeoOverlayConfiguration {
    let referencePlaces: [GeoReferencePlace]
    let cropToSlovenia: Bool
    let caption: String

    static let generic = GeoOverlayConfiguration(
        referencePlaces: SloveniaOverlayData.anchorCities,
        cropToSlovenia: false,
        caption: "Obris Slovenije pomaga pri orientaciji prikaza."
    )
}

struct TimelineImagePlayerView<Frame: TimelineFrameRepresentable>: View {
    let title: String
    let frames: [Frame]
    let cache: ImageCacheService
    let overlayConfiguration: GeoOverlayConfiguration

    @State private var selectedIndex = 0
    @State private var isPlaying = false

    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()
    private var frameURLs: [URL] { frames.map(\.imageURL) }

    init(
        title: String,
        frames: [Frame],
        cache: ImageCacheService,
        overlayConfiguration: GeoOverlayConfiguration = .generic
    ) {
        self.title = title
        self.frames = frames
        self.cache = cache
        self.overlayConfiguration = overlayConfiguration
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let frame = frames[safe: selectedIndex] {
                    let cropRect = frame.geoReference.flatMap(focusRect(for:))

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(uiColor: .secondarySystemBackground))

                        RemoteCachedImage(
                            url: frame.imageURL,
                            cache: cache,
                            normalizedCropRect: cropRect
                        )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                        if let geoReference = frame.geoReference {
                            SloveniaOutlineOverlay(
                                geoReference: geoReference,
                                referencePlaces: overlayConfiguration.referencePlaces,
                                cropRect: cropRect
                            )
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .allowsHitTesting(false)
                        }
                    }
                    .aspectRatio(frame.geoReference?.aspectRatio(croppedTo: cropRect) ?? frame.geoReference?.aspectRatio ?? (4 / 3), contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                    if frame.geoReference != nil {
                        Label(overlayConfiguration.caption, systemImage: "map")
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

    private func focusRect(for geoReference: FrameGeoReference) -> CGRect? {
        guard overlayConfiguration.cropToSlovenia else { return nil }

        let borderRect = geoReference.normalizedBounds(for: SloveniaOverlayData.border)
        let placesRect = geoReference.normalizedBounds(for: overlayConfiguration.referencePlaces)
        let combined = union(borderRect, placesRect)

        guard let combined else { return nil }

        return expandedRect(
            combined,
            top: 0.08,
            leading: 0.06,
            bottom: 0.12,
            trailing: 0.08
        )
    }

    private func union(_ lhs: CGRect?, _ rhs: CGRect?) -> CGRect? {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return lhs.union(rhs)
        case let (lhs?, nil):
            return lhs
        case let (nil, rhs?):
            return rhs
        case (nil, nil):
            return nil
        }
    }

    private func expandedRect(
        _ rect: CGRect,
        top: CGFloat,
        leading: CGFloat,
        bottom: CGFloat,
        trailing: CGFloat
    ) -> CGRect {
        let minX = max(0, rect.minX - leading)
        let minY = max(0, rect.minY - top)
        let maxX = min(1, rect.maxX + trailing)
        let maxY = min(1, rect.maxY + bottom)

        return CGRect(
            x: minX,
            y: minY,
            width: max(maxX - minX, 0.001),
            height: max(maxY - minY, 0.001)
        )
    }
}

private struct SloveniaOutlineOverlay: View {
    let geoReference: FrameGeoReference
    let referencePlaces: [GeoReferencePlace]
    let cropRect: CGRect?

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

                ForEach(referencePlaces) { city in
                    if let point = geoReference.normalizedPosition(latitude: city.latitude, longitude: city.longitude) {
                        CityAnchorLabel(
                            name: city.name,
                            anchor: rawPosition(for: point, in: geometry.size),
                            labelOffset: city.labelOffset
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
            path.move(to: rawPosition(for: first, in: size))

            for point in projected.dropFirst() {
                path.addLine(to: rawPosition(for: point, in: size))
            }
        }
    }

    private func rawPosition(for point: CGPoint, in size: CGSize) -> CGPoint {
        let visibleRect = cropRect ?? CGRect(x: 0, y: 0, width: 1, height: 1)
        let normalizedX = (point.x - visibleRect.minX) / max(visibleRect.width, 0.001)
        let normalizedY = (point.y - visibleRect.minY) / max(visibleRect.height, 0.001)

        return CGPoint(
            x: normalizedX * size.width,
            y: normalizedY * size.height
        )
    }
}

private struct CityAnchorLabel: View {
    let name: String
    let anchor: CGPoint
    let labelOffset: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(.white)
                .frame(width: 6, height: 6)
                .overlay {
                    Circle()
                        .stroke(Color.black.opacity(0.5), lineWidth: 1)
                }
                .position(anchor)

            Text(name)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.72), in: Capsule())
                .position(labelPosition)
        }
        .shadow(color: Color.black.opacity(0.28), radius: 5, y: 2)
    }

    private var labelPosition: CGPoint {
        CGPoint(
            x: anchor.x + labelOffset.width,
            y: anchor.y + labelOffset.height
        )
    }
}
