import CoreLocation
import Foundation
import SwiftUI

struct AirQualitySnapshot {
    let stations: [AirQualityStation]
    let measurementsByStationCode: [String: AirQualityMeasurement]
    let fetchedAt: Date
}

struct AirQualityStation: Identifiable, Hashable {
    let code: String
    let name: String
    let latitude: Double
    let longitude: Double

    var id: String { code }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct AirQualityMeasurement: Identifiable, Hashable {
    let stationCode: String
    let intervalStart: Date?
    let intervalEnd: Date?
    let pm25: Double?
    let pm10: Double?
    let no2: Double?
    let o3: Double?
    let so2: Double?
    let co: Double?

    var id: String { stationCode }
    var lastUpdate: Date? { intervalEnd ?? intervalStart }
}

struct AirQualityStationItem: Identifiable, Hashable {
    let station: AirQualityStation
    let measurement: AirQualityMeasurement?

    var id: String { station.id }
    var primaryValue: Double? { measurement?.pm25 ?? measurement?.pm10 }
    var primaryMetricLabel: String { measurement?.pm25 != nil ? "PM2.5" : "PM10" }

    var level: AirQualityLevel {
        AirQualityLevel.from(pm25: measurement?.pm25, pm10: measurement?.pm10)
    }
}

struct AirQualityChartPoint: Identifiable, Hashable {
    let date: Date
    let value: Double

    var id: String {
        "\(date.timeIntervalSince1970)-\(value)"
    }
}

enum AirQualityLevel: String, CaseIterable {
    case good
    case moderate
    case unhealthySensitive
    case unhealthy
    case veryUnhealthy
    case noData

    static func from(pm25: Double?, pm10: Double?) -> AirQualityLevel {
        if let pm25 {
            return fromPM25(pm25)
        }

        if let pm10 {
            return fromPM10(pm10)
        }

        return .noData
    }

    private static func fromPM25(_ value: Double?) -> AirQualityLevel {
        guard let value, value >= 0 else {
            return .noData
        }

        switch value {
        case 0 ... 15:
            return .good
        case 16 ... 35:
            return .moderate
        case 36 ... 55:
            return .unhealthySensitive
        case 56 ... 100:
            return .unhealthy
        default:
            return .veryUnhealthy
        }
    }

    private static func fromPM10(_ value: Double?) -> AirQualityLevel {
        guard let value, value >= 0 else {
            return .noData
        }

        switch value {
        case 0 ... 25:
            return .good
        case 26 ... 50:
            return .moderate
        case 51 ... 100:
            return .unhealthy
        default:
            return .veryUnhealthy
        }
    }

    var title: String {
        switch self {
        case .good:
            return "Dobro"
        case .moderate:
            return "Zmerno"
        case .unhealthySensitive:
            return "Nezdravo za občutljive"
        case .unhealthy:
            return "Nezdravo"
        case .veryUnhealthy:
            return "Zelo nezdravo"
        case .noData:
            return "Ni podatkov"
        }
    }

    var color: Color {
        switch self {
        case .good:
            return Color(red: 0.20, green: 0.74, blue: 0.42)
        case .moderate:
            return Color(red: 0.92, green: 0.74, blue: 0.22)
        case .unhealthySensitive:
            return Color(red: 0.93, green: 0.53, blue: 0.18)
        case .unhealthy:
            return Color(red: 0.88, green: 0.24, blue: 0.20)
        case .veryUnhealthy:
            return Color(red: 0.58, green: 0.32, blue: 0.82)
        case .noData:
            return .gray
        }
    }
}
