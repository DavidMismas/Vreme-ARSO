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

    func file(for url: URL, forceRefresh: Bool = false) async throws -> URL {
        let localURL = localURL(for: url)
        if forceRefresh {
            try? fileManager.removeItem(at: localURL)
            imageCache.removeObject(forKey: url as NSURL)
        }

        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        try data.write(to: localURL, options: .atomic)
        return localURL
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = imageCache.object(forKey: url as NSURL) {
            return cached
        }

        do {
            let fileURL = try await file(for: url)
            return try decodedImage(at: fileURL, originalURL: url)
        } catch {
            let refreshedFileURL = try await file(for: url, forceRefresh: true)
            return try decodedImage(at: refreshedFileURL, originalURL: url)
        }
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

    private func decodedImage(at fileURL: URL, originalURL: URL) throws -> UIImage {
        let data = try Data(contentsOf: fileURL)

        guard let image = UIImage(data: data) else {
            try? fileManager.removeItem(at: fileURL)
            imageCache.removeObject(forKey: originalURL as NSURL)
            throw URLError(.cannotDecodeContentData)
        }

        imageCache.setObject(image, forKey: originalURL as NSURL)
        return image
    }
}
