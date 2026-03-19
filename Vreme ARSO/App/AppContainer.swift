import Foundation

struct AppContainer {
    let apiClient: APIClient
    let xmlParserService: XMLParserService
    let rssParserService: RSSParserService
    let htmlTextExtractor: HTMLTextExtractor
    let imageCacheService: ImageCacheService
    let currentWeatherService: ARSOCurrentWeatherService
    let stationsService: ARSOStationsService
    let forecastTextService: ARSOForecastTextService
    let warningsService: ARSOWarningsService
    let radarService: ARSORadarService
    let satelliteService: ARSOSatelliteService
    let graphicForecastService: ARSOGraphicForecastService

    static let live: AppContainer = {
        let validator = ResponseValidator()
        let requestBuilder = RequestBuilder()
        let apiClient = APIClient(
            session: .shared,
            requestBuilder: requestBuilder,
            validator: validator
        )
        let xmlParserService = XMLParserService()
        let rssParserService = RSSParserService()
        let htmlTextExtractor = HTMLTextExtractor()
        let imageCacheService = ImageCacheService()

        return AppContainer(
            apiClient: apiClient,
            xmlParserService: xmlParserService,
            rssParserService: rssParserService,
            htmlTextExtractor: htmlTextExtractor,
            imageCacheService: imageCacheService,
            currentWeatherService: ARSOCurrentWeatherService(apiClient: apiClient, xmlParser: xmlParserService),
            stationsService: ARSOStationsService(apiClient: apiClient, xmlParser: xmlParserService),
            forecastTextService: ARSOForecastTextService(apiClient: apiClient, htmlExtractor: htmlTextExtractor),
            warningsService: ARSOWarningsService(apiClient: apiClient, xmlParser: xmlParserService),
            radarService: ARSORadarService(apiClient: apiClient),
            satelliteService: ARSOSatelliteService(apiClient: apiClient),
            graphicForecastService: ARSOGraphicForecastService(apiClient: apiClient)
        )
    }()
}
