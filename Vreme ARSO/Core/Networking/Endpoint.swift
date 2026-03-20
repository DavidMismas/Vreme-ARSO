import Foundation

enum Endpoint {
    enum GraphicKind: String, CaseIterable, Codable, Identifiable {
        case temperatura = "inca_t2m"
        case veter = "inca_wind"
        case oblacnost = "inca_sp"
        case padavine = "inca_tp"
        case radar = "inca_si0zm"
        case toca = "inca_hp"

        var id: String { rawValue }

        var naslov: String {
            switch self {
            case .temperatura: return "Temperatura"
            case .veter: return "Veter"
            case .oblacnost: return "Oblačnost"
            case .padavine: return "Padavine"
            case .radar: return "Radarska odbojnost"
            case .toca: return "Verjetnost toče"
            }
        }
    }

    case observationsOverview
    case forecastTextOverview
    case forecastTodayTomorrow
    case forecastOutlook
    case forecastLongRange
    case forecastNeighbours
    case forecastSynoptic
    case warningText
    case warningRegionCAP(regionID: String)
    case radarTimeline
    case satelliteLatestImage
    case satelliteLatestAnimation
    case coastForecast
    case mountainForecast
    case mountainSeaOverview
    case locationForecast(locationName: String)
    case nearestForecastLocation(latitude: Double, longitude: Double)
    case graphicTimeline(kind: GraphicKind)
    case graphicLatest(kind: GraphicKind)

    private static let baseURL = URL(string: "https://meteo.arso.gov.si")!
    private static let vremeBaseURL = URL(string: "https://vreme.arso.gov.si")!

    var url: URL {
        switch self {
        case .observationsOverview:
            return Self.baseURL.appending(path: "/uploads/probase/www/observ/surface/text/sl/observation_si_latest.xml")
        case .forecastTextOverview:
            return Self.baseURL.appending(path: "/uploads/probase/www/fproduct/text/sl/fcast_si_text.html")
        case .forecastTodayTomorrow:
            return Self.baseURL.appending(path: "/uploads/probase/www/fproduct/text/sl/fcast_SLOVENIA_d1-d2_text.html")
        case .forecastOutlook:
            return Self.baseURL.appending(path: "/uploads/probase/www/fproduct/text/sl/fcast_SLOVENIA_d3-d5_text.html")
        case .forecastLongRange:
            return Self.baseURL.appending(path: "/uploads/probase/www/fproduct/text/sl/fcast_SLOVENIA_d5-d10_text.html")
        case .forecastNeighbours:
            return Self.baseURL.appending(path: "/uploads/probase/www/fproduct/text/sl/fcast_SI_NEIGHBOURS_d1-d2_text.html")
        case .forecastSynoptic:
            return Self.baseURL.appending(path: "/uploads/probase/www/fproduct/text/sl/fcast_EUROPE_d1_text.html")
        case .warningText:
            return Self.baseURL.appending(path: "/uploads/probase/www/warning/text/sl/warning_SLOVENIA_text.html")
        case .warningRegionCAP(let regionID):
            return Self.baseURL.appending(path: "/uploads/probase/www/warning/text/sl/warning_\(regionID)_latest_CAP.xml")
        case .radarTimeline:
            return Self.baseURL.appending(path: "/uploads/probase/www/nowcast/inca/inca_si0zm_data.json")
        case .satelliteLatestImage:
            return Self.baseURL.appending(path: "/uploads/probase/www/observ/satellite/mtg_geocolor_si-neighbours_latest.jpg")
        case .satelliteLatestAnimation:
            return Self.baseURL.appending(path: "/uploads/probase/www/observ/satellite/mtg_geocolor_si-neighbours_latest.mp4")
        case .coastForecast:
            return Self.baseURL.appending(path: "/uploads/probase/www/fproduct/text/sl/fcast_si-coast_latest.html")
        case .mountainForecast:
            return Self.baseURL.appending(path: "/uploads/probase/www/fproduct/text/sl/forecast_si-mountain_latest.html")
        case .mountainSeaOverview:
            return Self.baseURL.appending(path: "/uploads/probase/www/sproduct/mountain/")
        case .locationForecast(let locationName):
            var components = URLComponents(url: Self.vremeBaseURL.appending(path: "/api/1.0/location/"), resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "lang", value: "sl"),
                URLQueryItem(name: "location", value: locationName)
            ]
            return components?.url ?? Self.vremeBaseURL.appending(path: "/api/1.0/location/")
        case .nearestForecastLocation(let latitude, let longitude):
            var components = URLComponents(url: Self.vremeBaseURL.appending(path: "/api/1.0/locations/"), resolvingAgainstBaseURL: false)
            components?.queryItems = [
                URLQueryItem(name: "lat", value: String(latitude)),
                URLQueryItem(name: "lon", value: String(longitude))
            ]
            return components?.url ?? Self.vremeBaseURL.appending(path: "/api/1.0/locations/")
        case .graphicTimeline(let kind):
            return Self.baseURL.appending(path: "/uploads/probase/www/nowcast/inca/\(kind.rawValue)_data.json")
        case .graphicLatest(let kind):
            return Self.baseURL.appending(path: "/uploads/probase/www/nowcast/inca/\(kind.rawValue)_latest.png")
        }
    }

    var refreshPolicy: RefreshPolicy {
        switch self {
        case .observationsOverview:
            return .currentConditions
        case .radarTimeline, .satelliteLatestImage, .satelliteLatestAnimation, .coastForecast, .mountainForecast, .mountainSeaOverview, .graphicTimeline, .graphicLatest:
            return .imagery
        default:
            return .forecastText
        }
    }
}
