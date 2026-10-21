import Foundation

// Shared with the widget extension so selection and parsing use the same contract.
enum WidgetSupplementKind: String, CaseIterable, Identifiable, Codable {
    case sea, snow, air
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sea: return "Temperatura morja"
        case .snow: return "Snežna odeja"
        case .air: return "Kakovost zraka"
        }
    }
    var symbol: String {
        switch self {
        case .sea: return "water.waves"
        case .snow: return "snowflake"
        case .air: return "aqi.medium"
        }
    }
}

struct WidgetSupplementSelection: Equatable {
    let kind: WidgetSupplementKind
    let stationID: String
    let stationName: String

    static func read(from defaults: UserDefaults?) -> Self {
        let kind = WidgetSupplementKind(rawValue: defaults?.string(forKey: "widgetSupplementKind") ?? "") ?? .sea
        let prefix = kind == .snow ? "widgetSnow" : "widgetAir"
        return Self(kind: kind, stationID: defaults?.string(forKey: "\(prefix)StationID") ?? "", stationName: defaults?.string(forKey: "\(prefix)StationName") ?? "")
    }

    var cacheKey: String { "\(kind.rawValue)|\(stationID)|\(stationName)" }
    var unavailable: WidgetSupplementValue {
        WidgetSupplementValue(kind: kind, stationName: kind == .sea ? "Obala" : stationName,
                              value: stationID.isEmpty && kind != .sea ? "Izberi postajo" : "Ni podatka", measuredAt: nil)
    }
}

struct WidgetSupplementValue: Codable, Equatable {
    let kind: WidgetSupplementKind
    let stationName: String
    let value: String
    let measuredAt: Date?

    var text: String {
        let label = kind == .snow ? "Sneg · " : ""
        let station = stationName.isEmpty ? "" : "\(stationName) · "
        let stale = measuredAt.map { Date().timeIntervalSince($0) > (kind == .air ? 12 : 36) * 3600 } ?? false
        return "\(label)\(station)\(value)\(stale ? " · starejše" : "")"
    }
}

enum WidgetSupplementParser {
    static func snow(data: Data, selection: WidgetSupplementSelection) throws -> WidgetSupplementValue {
        let root = try XMLParserService().parse(data: data)
        guard let station = root.children(named: "metData").first(where: {
            ($0.textValue(forChild: "domain_meteosiId") ?? $0.textValue(forChild: "domain_longTitle")) == selection.stationID
        }), let raw = station.textValue(forChild: "snow"), let depth = Int(raw), depth >= 0 else {
            return selection.unavailable
        }
        return WidgetSupplementValue(kind: .snow, stationName: selection.stationName, value: "\(depth) cm",
                                     measuredAt: DateFormatterSI.parseARSODate(station.textValue(forChild: "tsUpdated")))
    }

    static func air(data: Data, selection: WidgetSupplementSelection) throws -> WidgetSupplementValue {
        let measurements = try AirQualityMeasurementsXMLParser().parse(data: data)
        guard let measurement = measurements.filter({ $0.stationCode == selection.stationID }).max(by: {
            ($0.lastUpdate ?? .distantPast) < ($1.lastUpdate ?? .distantPast)
        }) else { return selection.unavailable }
        let pm25 = measurement.pm25.flatMap { $0 >= 0 ? $0 : nil }
        let pm10 = measurement.pm10.flatMap { $0 >= 0 ? $0 : nil }
        guard let value = pm25 ?? pm10 else { return selection.unavailable }
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "sl_SI")
        formatter.maximumFractionDigits = 1
        let number = formatter.string(from: NSNumber(value: value)) ?? String(value)
        return WidgetSupplementValue(kind: .air, stationName: selection.stationName,
                                     value: "\(pm25 != nil ? "PM2.5" : "PM10") \(number) µg/m³", measuredAt: measurement.lastUpdate)
    }
}
