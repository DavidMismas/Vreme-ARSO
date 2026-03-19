import Foundation

struct ResponseValidator {
    func validate(response: URLResponse, data: Data) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ARSOError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            throw ARSOError.httpError(statusCode: httpResponse.statusCode)
        }

        guard !data.isEmpty else {
            throw ARSOError.emptyResponse
        }

        return httpResponse
    }
}
