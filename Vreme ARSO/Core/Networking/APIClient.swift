import Foundation

struct APIResponse {
    let data: Data
    let response: HTTPURLResponse
}

protocol APIClientProtocol {
    func response(for endpoint: Endpoint) async throws -> APIResponse
    func data(for endpoint: Endpoint) async throws -> Data
}

struct APIClient: APIClientProtocol {
    let session: URLSession
    let requestBuilder: RequestBuilder
    let validator: ResponseValidator

    func response(for endpoint: Endpoint) async throws -> APIResponse {
        let request = try requestBuilder.makeRequest(for: endpoint)
        NSLog("Zahteva: %@", request.url?.absoluteString ?? "neznan URL")
        let (data, response) = try await session.data(for: request)
        let httpResponse = try validator.validate(response: response, data: data)
        return APIResponse(data: data, response: httpResponse)
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        try await response(for: endpoint).data
    }
}
