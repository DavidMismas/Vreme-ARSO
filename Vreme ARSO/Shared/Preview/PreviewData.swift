import Foundation

enum PreviewData {
    static let frameGeoReference = FrameGeoReference(
        bbox: "44.67,12.1,47.42,17.44",
        width: "800",
        height: "600"
    )

    static let station = WeatherStation(
        id: "LJUBL-ANA_BEZIGRAD_",
        name: "Ljubljana",
        latitude: 46.0514,
        longitude: 14.506,
        elevation: 299,
        region: "SI_OSREDNJESLOVENSKA_",
        isFavorite: true
    )

    static let observation = CurrentObservation(
        stationID: station.id,
        timestamp: Date(),
        temperature: 12,
        apparentTemperature: 10.8,
        humidity: 56,
        pressure: 1016,
        windSpeed: 3.8,
        windGust: 6.1,
        windDirection: "SV",
        windDirectionDegrees: 45,
        precipitation: 0,
        cloudiness: "delno oblačno",
        weatherSymbol: "partCloudy",
        weatherDescription: "delno oblačno",
        visibilityKilometers: 25,
        source: "ARSO"
    )

    static let warning = WarningItem(
        id: "preview-warning",
        title: "Veter - zmerna ogroženost",
        severity: .moderate,
        area: "Slovenija / osrednja",
        validFrom: Date(),
        validTo: Date().addingTimeInterval(6 * 60 * 60),
        body: "Možni so močnejši sunki vetra na izpostavljenih legah.",
        eventType: "wind",
        polygons: []
    )

    static let forecastSections: [ForecastTextSection] = ForecastTextSectionType.allCases.map { type in
        ForecastTextSection(
            id: type.rawValue,
            type: type,
            title: type.naslov,
            body: "Vzorec vsebine za sekcijo \(type.naslov.lowercased()).",
            issuedAt: Date(),
            sourceURL: Endpoint.forecastTextOverview.url
        )
    }

    static let radarFrames: [RadarFrame] = (0..<5).map { index in
        RadarFrame(
            id: "\(index)",
            timestamp: Date().addingTimeInterval(Double(index) * 300),
            imageURL: Endpoint.graphicLatest(kind: .radar).url,
            cachedLocalPath: nil,
            geoReference: frameGeoReference
        )
    }

    static let graphicItem = GraphicForecastItem(
        id: Endpoint.GraphicKind.temperatura.id,
        kind: .temperatura,
        title: "Temperatura",
        frames: (0..<4).map { index in
            GraphicFrame(
                id: "\(index)",
                timestamp: Date().addingTimeInterval(Double(index) * 3600),
                imageURL: Endpoint.graphicLatest(kind: .temperatura).url,
                cachedLocalPath: nil,
                geoReference: frameGeoReference
            )
        },
        latestImageURL: Endpoint.graphicLatest(kind: .temperatura).url,
        updatedAt: Date(),
        source: "ARSO"
    )
}
