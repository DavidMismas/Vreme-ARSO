import SwiftUI
import UIKit

struct RemoteCachedImage: View {
    let url: URL
    let cache: ImageCacheService
    let contentMode: ContentMode

    @State private var uiImage: UIImage?
    @State private var loadedURL: URL?
    @State private var isLoading = false

    init(url: URL, cache: ImageCacheService, contentMode: ContentMode = .fit) {
        self.url = url
        self.cache = cache
        self.contentMode = contentMode
    }

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
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
