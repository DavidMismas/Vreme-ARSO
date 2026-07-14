import Foundation

nonisolated final class AirQualityStationsXMLParser: NSObject {
    private struct StationBuilder {
        var code = ""
        var name = ""
        var latitude: Double?
        var longitude: Double?
    }

    nonisolated private final class Delegate: NSObject, XMLParserDelegate {
        private(set) var stations: [AirQualityStation] = []

        private var currentBuilder: StationBuilder?
        private var currentText = ""

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            currentText = ""

            guard elementName == "postaja" else {
                return
            }

            var builder = StationBuilder()
            builder.code = attributeDict["sifra"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            builder.latitude = parseDouble(attributeDict["wgs84_sirina"])
            builder.longitude = parseDouble(attributeDict["wgs84_dolzina"])
            currentBuilder = builder
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            currentText.append(string)
        }

        func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

            if elementName == "merilno_mesto" {
                currentBuilder?.name = value
            }

            if elementName == "postaja", let builder = currentBuilder {
                defer { currentBuilder = nil }

                guard !builder.code.isEmpty,
                      let latitude = builder.latitude,
                      let longitude = builder.longitude else {
                    return
                }

                stations.append(
                    AirQualityStation(
                        code: builder.code,
                        name: builder.name.isEmpty ? builder.code : builder.name,
                        latitude: latitude,
                        longitude: longitude
                    )
                )
            }

            currentText = ""
        }

        private func parseDouble(_ rawValue: String?) -> Double? {
            guard let rawValue else { return nil }
            let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return Double(trimmed.replacingOccurrences(of: ",", with: "."))
        }
    }

    nonisolated func parse(data: Data) throws -> [AirQualityStation] {
        let parser = XMLParser(data: data)
        let delegate = Delegate()
        parser.delegate = delegate

        guard parser.parse() else {
            throw parser.parserError ?? ARSOError.parsingFailed("ARSO zračnih postaj ni bilo mogoče prebrati.")
        }

        return delegate.stations
    }
}

nonisolated final class AirQualityMeasurementsXMLParser: NSObject {
    private struct MeasurementBuilder {
        var stationCode = ""
        var intervalStart: Date?
        var intervalEnd: Date?
        var pm25: Double?
        var pm10: Double?
        var no2: Double?
        var o3: Double?
        var so2: Double?
        var co: Double?
    }

    nonisolated private final class Delegate: NSObject, XMLParserDelegate {
        private(set) var measurements: [AirQualityMeasurement] = []

        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter
        }()

        private var currentBuilder: MeasurementBuilder?
        private var currentText = ""

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            currentText = ""

            guard elementName == "postaja" else {
                return
            }

            var builder = MeasurementBuilder()
            builder.stationCode = attributeDict["sifra"]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            currentBuilder = builder
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            currentText.append(string)
        }

        func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            let value = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

            switch elementName {
            case "datum_od":
                currentBuilder?.intervalStart = parseDate(value)
            case "datum_do":
                currentBuilder?.intervalEnd = parseDate(value)
            case "pm2.5":
                currentBuilder?.pm25 = parseMeasurement(value)
            case "pm10":
                currentBuilder?.pm10 = parseMeasurement(value)
            case "no2":
                currentBuilder?.no2 = parseMeasurement(value)
            case "o3":
                currentBuilder?.o3 = parseMeasurement(value)
            case "so2":
                currentBuilder?.so2 = parseMeasurement(value)
            case "co":
                currentBuilder?.co = parseMeasurement(value)
            case "postaja":
                if let builder = currentBuilder, !builder.stationCode.isEmpty {
                    measurements.append(
                        AirQualityMeasurement(
                            stationCode: builder.stationCode,
                            intervalStart: builder.intervalStart,
                            intervalEnd: builder.intervalEnd,
                            pm25: builder.pm25,
                            pm10: builder.pm10,
                            no2: builder.no2,
                            o3: builder.o3,
                            so2: builder.so2,
                            co: builder.co
                        )
                    )
                }
                currentBuilder = nil
            default:
                break
            }

            currentText = ""
        }

        private func parseDate(_ value: String) -> Date? {
            guard !value.isEmpty else { return nil }
            return Self.dateFormatter.date(from: value)
        }

        private func parseMeasurement(_ value: String) -> Double? {
            guard !value.isEmpty else { return nil }

            let normalized = value.replacingOccurrences(of: ",", with: ".")
            let numericOnly = normalized.filter {
                $0.isNumber || $0 == "." || $0 == "-"
            }

            guard !numericOnly.isEmpty else { return nil }
            return Double(numericOnly)
        }
    }

    nonisolated func parse(data: Data) throws -> [AirQualityMeasurement] {
        let parser = XMLParser(data: data)
        let delegate = Delegate()
        parser.delegate = delegate

        guard parser.parse() else {
            throw parser.parserError ?? ARSOError.parsingFailed("ARSO meritev zraka ni bilo mogoče prebrati.")
        }

        return delegate.measurements
    }
}
