import Foundation

struct ARSOSatelliteService {
    let apiClient: APIClientProtocol

    func fetchLatestFrame() async throws -> SatelliteFrame {
        let imageResponse = try await apiClient.response(for: .satelliteLatestImage)
        let headerDate = imageResponse.response.value(forHTTPHeaderField: "Last-Modified")
        let timestamp = headerDate.flatMap(HTTPDateParser.parse)

        return SatelliteFrame(
            id: "satellite-latest",
            timestamp: timestamp,
            imageURL: Endpoint.satelliteLatestImage.url,
            animationURL: Endpoint.satelliteLatestAnimation.url,
            cachedLocalPath: nil
        )
    }
}

private enum HTTPDateParser {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }()

    static func parse(_ string: String) -> Date? {
        formatter.date(from: string)
    }
}
