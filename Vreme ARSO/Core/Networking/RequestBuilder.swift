import Foundation

struct RequestBuilder {
    func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        var request = URLRequest(url: endpoint.url)
        request.cachePolicy = .useProtocolCachePolicy
        request.timeoutInterval = 30
        request.setValue("VremeARSO/1.0 (iOS; native SwiftUI app)", forHTTPHeaderField: "User-Agent")
        return request
    }
}
