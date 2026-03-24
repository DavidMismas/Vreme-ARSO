import Foundation

struct AppContainer {
    let apiClient: APIClient
    let xmlParserService: XMLParserService
    let rssParserService: RSSParserService
    let htmlTextExtractor: HTMLTextExtractor
    let imageCacheService: ImageCacheService
    let weatherIconProvider: WeatherIconProvider
    let locationResolver: LocationResolver
    let currentWeatherService: ARSOCurrentWeatherService
    let stationsService: ARSOStationsService
    let forecastTextService: ARSOForecastTextService
    let warningsService: ARSOWarningsService
    let radarService: ARSORadarService
    let satelliteService: ARSOSatelliteService
    let waterTemperaturesService: ARSOWaterTemperaturesService
    let mountainConditionsService: ARSOMountainConditionsService
    let skiConditionsService: ARSOSkiConditionsService
    let graphicForecastService: ARSOGraphicForecastService
    let locationForecastService: ARSOLocationForecastService

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
        let weatherIconProvider = WeatherIconProvider()
        let locationResolver = LocationResolver(forecastProvider: StationForecastLocationProvider())

        return AppContainer(
            apiClient: apiClient,
            xmlParserService: xmlParserService,
            rssParserService: rssParserService,
            htmlTextExtractor: htmlTextExtractor,
            imageCacheService: imageCacheService,
            weatherIconProvider: weatherIconProvider,
            locationResolver: locationResolver,
            currentWeatherService: ARSOCurrentWeatherService(apiClient: apiClient, xmlParser: xmlParserService),
            stationsService: ARSOStationsService(apiClient: apiClient, xmlParser: xmlParserService),
            forecastTextService: ARSOForecastTextService(apiClient: apiClient, htmlExtractor: htmlTextExtractor),
            warningsService: ARSOWarningsService(apiClient: apiClient, xmlParser: xmlParserService),
            radarService: ARSORadarService(apiClient: apiClient),
            satelliteService: ARSOSatelliteService(apiClient: apiClient),
            waterTemperaturesService: ARSOWaterTemperaturesService(apiClient: apiClient),
            mountainConditionsService: ARSOMountainConditionsService(apiClient: apiClient),
            skiConditionsService: ARSOSkiConditionsService(apiClient: apiClient, xmlParser: xmlParserService),
            graphicForecastService: ARSOGraphicForecastService(apiClient: apiClient),
            locationForecastService: ARSOLocationForecastService(apiClient: apiClient)
        )
    }()
}
