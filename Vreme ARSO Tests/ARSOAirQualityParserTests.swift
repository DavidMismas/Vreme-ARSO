import XCTest
@testable import Vreme_ARSO

final class ARSOAirQualityParserTests: XCTestCase {
    func testParsesStationsAndMeasurementsFromARSOSample() throws {
        let data = """
        <?xml version="1.0" encoding="UTF-8"?>
        <arsopodatki verzija="1.5">
          <postaja sifra="E403" wgs84_dolzina="14.5127203" wgs84_sirina="46.0655449">
            <merilno_mesto>LJ Bežigrad</merilno_mesto>
            <datum_od>2026-07-14 20:00</datum_od>
            <datum_do>2026-07-14 21:00</datum_do>
            <co>0.1</co>
            <o3>93</o3>
            <no2>&lt;1</no2>
            <pm10>12</pm10>
            <pm2.5>7</pm2.5>
          </postaja>
        </arsopodatki>
        """.data(using: .utf8)!

        let stations = try AirQualityStationsXMLParser().parse(data: data)
        let measurements = try AirQualityMeasurementsXMLParser().parse(data: data)

        XCTAssertEqual(stations.count, 1)
        XCTAssertEqual(stations.first?.code, "E403")
        XCTAssertEqual(stations.first?.name, "LJ Bežigrad")
        XCTAssertEqual(stations.first?.latitude, 46.0655449)
        XCTAssertEqual(stations.first?.longitude, 14.5127203)

        XCTAssertEqual(measurements.count, 1)
        XCTAssertEqual(measurements.first?.stationCode, "E403")
        XCTAssertEqual(measurements.first?.pm25, 7)
        XCTAssertEqual(measurements.first?.pm10, 12)
        XCTAssertEqual(measurements.first?.no2, 1)
        XCTAssertEqual(measurements.first?.o3, 93)
        XCTAssertEqual(measurements.first?.co, 0.1)
        XCTAssertEqual(measurements.first?.lastUpdate, AirQualityTestDateFormatter.formatter.date(from: "2026-07-14 21:00"))
    }

    func testAirQualityLevelPrefersPM25ThenFallsBackToPM10() {
        XCTAssertEqual(AirQualityLevel.from(pm25: 7, pm10: 60), .good)
        XCTAssertEqual(AirQualityLevel.from(pm25: nil, pm10: 60), .unhealthy)
        XCTAssertEqual(AirQualityLevel.from(pm25: nil, pm10: nil), .noData)
    }
}

private enum AirQualityTestDateFormatter {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Ljubljana")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}
