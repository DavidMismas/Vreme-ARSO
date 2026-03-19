import Foundation

struct ARSOObservationFeedMapper {
    func map(root: XMLNode) -> (stations: [WeatherStation], observations: [CurrentObservation]) {
        let items = root.children(named: "metData")
        let stations = items.map(makeStation)
        let observations = items.map(makeObservation)
        return (stations, observations)
    }

    private func makeStation(from node: XMLNode) -> WeatherStation {
        WeatherStation(
            id: node.textValue(forChild: "domain_meteosiId") ?? UUID().uuidString,
            name: node.textValue(forChild: "domain_longTitle") ?? node.textValue(forChild: "domain_shortTitle") ?? "Neznana postaja",
            latitude: Double(node.textValue(forChild: "domain_lat") ?? "") ?? 0,
            longitude: Double(node.textValue(forChild: "domain_lon") ?? "") ?? 0,
            elevation: Double(node.textValue(forChild: "domain_altitude") ?? ""),
            region: node.textValue(forChild: "domain_parentId"),
            isFavorite: false
        )
    }

    private func makeObservation(from node: XMLNode) -> CurrentObservation {
        let temperature = Double(node.textValue(forChild: "t") ?? "")
        let humidity = Int(node.textValue(forChild: "rh") ?? "")
        let windSpeed = Double(node.textValue(forChild: "ff_val") ?? "")
        let windGust = Double(node.textValue(forChild: "ffmax_val") ?? "")

        return CurrentObservation(
            stationID: node.textValue(forChild: "domain_meteosiId") ?? UUID().uuidString,
            timestamp: DateFormatterSI.parseARSODate(node.textValue(forChild: "tsUpdated")),
            temperature: temperature,
            apparentTemperature: Self.apparentTemperature(
                airTemperature: temperature,
                humidity: humidity,
                windSpeed: windSpeed
            ),
            humidity: humidity,
            pressure: Double(node.textValue(forChild: "msl") ?? "") ?? Double(node.textValue(forChild: "p") ?? ""),
            windSpeed: windSpeed,
            windGust: windGust,
            windDirection: node.textValue(forChild: "dd_shortText"),
            windDirectionDegrees: Double(node.textValue(forChild: "dd_val") ?? ""),
            precipitation: Double(node.textValue(forChild: "rr24h_val") ?? ""),
            cloudiness: node.textValue(forChild: "nn_shortText"),
            weatherSymbol: node.textValue(forChild: "nn_icon-wwsyn_icon") ?? node.textValue(forChild: "nn_icon"),
            weatherDescription: node.textValue(forChild: "nn_shortText-wwsyn_longText") ?? node.textValue(forChild: "nn_shortText"),
            visibilityKilometers: Double(node.textValue(forChild: "vis_value") ?? ""),
            source: rootSource(from: node)
        )
    }

    private func rootSource(from node: XMLNode) -> String {
        node.parent?.textValue(forChild: "credit") ?? "ARSO"
    }

    private static func apparentTemperature(airTemperature: Double?, humidity: Int?, windSpeed: Double?) -> Double? {
        guard let airTemperature else { return nil }
        let humidityFactor = humidity.map { Double($0) / 100 } ?? 0
        let windCooling = (windSpeed ?? 0) * 0.7
        return airTemperature + humidityFactor - windCooling
    }
}
