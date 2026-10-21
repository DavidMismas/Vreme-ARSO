import CoreLocation
import Foundation

struct PrecipitationReading: Codable, Equatable, Sendable {
    let stationID: String
    let stationName: String
    let amountMillimeters: Double
    let validAt: Date
    let periodStart: Date

    var periodLabel: String {
        "Padavine od \(Self.localTimeFormatter.string(from: periodStart))"
    }

    private static let localTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "H.mm"
        return formatter
    }()
}

struct PrecipitationStation: Sendable {
    let reading: PrecipitationReading
    let coordinate: CLLocationCoordinate2D
}

struct PrecipitationStationStatus: Identifiable, Sendable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D?
    let reading: PrecipitationReading?
}

enum ARSOPrecipitationParser {
    static func parse(data: Data, now: Date = .now) throws -> [PrecipitationStation] {
        try parseStations(data: data, now: now).compactMap { station in
            guard let reading = station.reading, let coordinate = station.coordinate else { return nil }
            return PrecipitationStation(reading: reading, coordinate: coordinate)
        }
    }

    static func parseStations(data: Data, now: Date = .now) throws -> [PrecipitationStationStatus] {
        let root = try XMLParserService().parse(data: data)
        return root.children(named: "metData").compactMap { node in
            guard let id = node.textValue(forChild: "domain_meteosiId"),
                  let name = node.textValue(forChild: "domain_longTitle") else { return nil }
            let coordinate: CLLocationCoordinate2D?
            if let latitude = Double(node.textValue(forChild: "domain_lat") ?? ""),
               let longitude = Double(node.textValue(forChild: "domain_lon") ?? "") {
                coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            } else {
                coordinate = nil
            }

            var reading: PrecipitationReading?
            if let valid = DateFormatterSI.parseARSODate(node.textValue(forChild: "valid")),
               now.timeIntervalSince(valid) >= -600,
               now.timeIntervalSince(valid) <= 3 * 3600,
               let raw = node.textValue(forChild: "tp_12h_acc"),
               let amount = Double(raw.replacingOccurrences(of: ",", with: ".")),
               amount.isFinite, amount >= 0 {
                reading = PrecipitationReading(stationID: id, stationName: name,
                                               amountMillimeters: amount, validAt: valid,
                                               periodStart: periodStart(for: valid))
            }
            return PrecipitationStationStatus(id: id, name: name, coordinate: coordinate, reading: reading)
        }
    }

    private static func periodStart(for valid: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let hour = calendar.component(.hour, from: valid)
        if hour < 6 {
            let previousDay = calendar.date(byAdding: .day, value: -1, to: valid) ?? valid
            return calendar.date(bySettingHour: 18, minute: 0, second: 0, of: previousDay) ?? valid
        }
        return calendar.date(bySettingHour: hour < 18 ? 6 : 18, minute: 0, second: 0, of: valid) ?? valid
    }
}

