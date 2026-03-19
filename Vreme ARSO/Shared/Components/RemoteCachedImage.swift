import SwiftUI
import UIKit

struct RemoteCachedImage: View {
    let url: URL
    let cache: ImageCacheService
    let contentMode: ContentMode
    let normalizedCropRect: CGRect?

    @State private var uiImage: UIImage?
    @State private var loadedURL: URL?
    @State private var isLoading = false

    init(
        url: URL,
        cache: ImageCacheService,
        contentMode: ContentMode = .fit,
        normalizedCropRect: CGRect? = nil
    ) {
        self.url = url
        self.cache = cache
        self.contentMode = contentMode
        self.normalizedCropRect = normalizedCropRect
    }

    var body: some View {
        Group {
            if let uiImage {
                imageView(for: uiImage)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Color.secondary.opacity(0.08)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .task(id: url) {
            await load(for: url)
        }
    }

    @ViewBuilder
    private func imageView(for image: UIImage) -> some View {
        if let normalizedCropRect {
            GeometryReader { geometry in
                let cropRect = normalizedCropRect.standardized
                let width = geometry.size.width / max(cropRect.width, 0.001)
                let height = geometry.size.height / max(cropRect.height, 0.001)

                Image(uiImage: image)
                    .resizable()
                    .frame(width: width, height: height)
                    .offset(
                        x: -cropRect.minX * width,
                        y: -cropRect.minY * height
                    )
            }
            .clipped()
        } else {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        }
    }

    @MainActor
    private func load(for targetURL: URL) async {
        if loadedURL == targetURL, uiImage != nil {
            return
        }

        isLoading = true
        defer {
            if targetURL == url {
                isLoading = false
            }
        }

        do {
            let nextImage = try await cache.image(for: targetURL)
            guard targetURL == url else { return }

            uiImage = nextImage
            loadedURL = targetURL
        } catch {
            NSLog("Slike ni bilo mogoče naložiti: %@", error.localizedDescription)
        }
    }
}
