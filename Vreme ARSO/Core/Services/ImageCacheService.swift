import Foundation
import UIKit

actor ImageCacheService {
    private let fileManager = FileManager.default
    private let imageCache = NSCache<NSURL, UIImage>()
    private lazy var cacheDirectory: URL = {
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first ?? URL(filePath: NSTemporaryDirectory())
        let directory = base.appending(path: "arso-images", directoryHint: .isDirectory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }()

    func cachedImage(for url: URL) -> UIImage? {
        imageCache.object(forKey: url as NSURL)
    }

    func cachedFile(for url: URL) -> URL? {
        let localURL = localURL(for: url)
        return fileManager.fileExists(atPath: localURL.path) ? localURL : nil
    }

    func file(for url: URL) async throws -> URL {
        let localURL = localURL(for: url)
        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: localURL, options: .atomic)
        return localURL
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = imageCache.object(forKey: url as NSURL) {
            return cached
        }

        let fileURL = try await file(for: url)
        let data = try Data(contentsOf: fileURL)

        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        imageCache.setObject(image, forKey: url as NSURL)
        return image
    }

    func preload(urls: [URL]) async {
        for url in urls {
            _ = try? await image(for: url)
        }
    }

    private func localURL(for remoteURL: URL) -> URL {
        let fileName = remoteURL.absoluteString
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appending(path: fileName)
    }
}
