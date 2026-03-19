import Foundation

enum ARSOError: LocalizedError {
    case invalidResponse
    case emptyResponse
    case httpError(statusCode: Int)
    case parsingFailed(String)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Vir podatkov je vrnil neveljaven odgovor."
        case .emptyResponse:
            return "Vir podatkov trenutno ne vrača vsebine."
        case .httpError(let statusCode):
            return "Vir podatkov ARSO je vrnil HTTP \(statusCode)."
        case .parsingFailed(let message):
            return message
        case .noData:
            return "Podatki trenutno niso na voljo."
        }
    }
}
