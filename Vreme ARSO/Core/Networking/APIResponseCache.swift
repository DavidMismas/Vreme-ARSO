import Foundation

actor APIResponseCache {
    static let shared = APIResponseCache()

    private var entries: [String: CachedAPIResponse] = [:]

    func response(for endpoint: Endpoint) -> APIResponse? {
        let key = cacheKey(for: endpoint)

        guard
            let entry = entries[key],
            Date().timeIntervalSince(entry.storedAt) < endpoint.refreshPolicy.interval,
            let response = HTTPURLResponse(
                url: endpoint.url,
                statusCode: entry.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: entry.headerFields
            )
        else {
            return nil
        }

        return APIResponse(data: entry.data, response: response)
    }

    func store(_ response: APIResponse, for endpoint: Endpoint) {
        let key = cacheKey(for: endpoint)
        entries[key] = CachedAPIResponse(
            data: response.data,
            statusCode: response.response.statusCode,
            headerFields: normalizedHeaders(from: response.response.allHeaderFields),
            storedAt: Date()
        )
    }

    private func cacheKey(for endpoint: Endpoint) -> String {
        endpoint.url.absoluteString
    }

    private func normalizedHeaders(from fields: [AnyHashable: Any]) -> [String: String] {
        fields.reduce(into: [:]) { result, pair in
            guard let key = pair.key as? String else { return }
            result[key] = String(describing: pair.value)
        }
    }
}

private struct CachedAPIResponse: Sendable {
    let data: Data
    let statusCode: Int
    let headerFields: [String: String]
    let storedAt: Date
}
