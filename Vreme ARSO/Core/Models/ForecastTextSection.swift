import Foundation

enum ForecastTextSectionType: String, CaseIterable, Identifiable, Sendable {
    case napoved
    case opozorilo
    case obeti
    case petDoDesetDni
    case sosednjePokrajine
    case vremenskaSlika
    case celoBesedilo

    var id: String { rawValue }

    var naslov: String {
        switch self {
        case .napoved: return "Napoved"
        case .opozorilo: return "Opozorilo"
        case .obeti: return "Obeti"
        case .petDoDesetDni: return "5 do 10 dni"
        case .sosednjePokrajine: return "Sosednje pokrajine"
        case .vremenskaSlika: return "Vremenska slika"
        case .celoBesedilo: return "Celo besedilo"
        }
    }
}

struct ForecastTextSection: Identifiable, Hashable, Sendable {
    let id: String
    let type: ForecastTextSectionType
    let title: String
    let body: String
    let issuedAt: Date?
    let sourceURL: URL
}
