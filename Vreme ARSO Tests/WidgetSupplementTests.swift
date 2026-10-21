import XCTest
@testable import Vreme_ARSO

final class WidgetSupplementTests: XCTestCase {
    private let snow = WidgetSupplementSelection(kind: .snow, stationID: "VOGEL", stationName: "Vogel")
    private let air = WidgetSupplementSelection(kind: .air, stationID: "E403", stationName: "LJ Bežigrad")

    func testSnowDistinguishesZeroFromMissingMeasurement() throws {
        let zero = Data("<data><metData><domain_meteosiId>VOGEL</domain_meteosiId><snow>0</snow></metData></data>".utf8)
        XCTAssertEqual(try WidgetSupplementParser.snow(data: zero, selection: snow).value, "0 cm")
        let missing = Data("<data><metData><domain_meteosiId>VOGEL</domain_meteosiId></metData></data>".utf8)
        XCTAssertEqual(try WidgetSupplementParser.snow(data: missing, selection: snow).value, "Ni podatka")
    }

    func testSnowUsesOnlySelectedStationAndRejectsNegativeDepth() throws {
        let data = Data("<data><metData><domain_meteosiId>OTHER</domain_meteosiId><snow>120</snow></metData><metData><domain_meteosiId>VOGEL</domain_meteosiId><snow>-1</snow></metData></data>".utf8)
        XCTAssertEqual(try WidgetSupplementParser.snow(data: data, selection: snow).value, "Ni podatka")
    }

    func testAirPrefersPM25AndPreservesStationAndUnits() throws {
        let data = Data("<arsopodatki><postaja sifra=\"E403\"><pm2.5>7.5</pm2.5><pm10>24</pm10></postaja></arsopodatki>".utf8)
        let result = try WidgetSupplementParser.air(data: data, selection: air)
        XCTAssertEqual(result.value, "PM2.5 7,5 µg/m³")
        XCTAssertEqual(result.stationName, "LJ Bežigrad")
    }

    func testAirFallsBackToPM10IncludingZero() throws {
        let data = Data("<arsopodatki><postaja sifra=\"E403\"><pm2.5>-1</pm2.5><pm10>0</pm10></postaja></arsopodatki>".utf8)
        XCTAssertEqual(try WidgetSupplementParser.air(data: data, selection: air).value, "PM10 0 µg/m³")
    }

    func testAirDoesNotUseOtherStationOrInventMissingValue() throws {
        let data = Data("<arsopodatki><postaja sifra=\"OTHER\"><pm2.5>10</pm2.5></postaja></arsopodatki>".utf8)
        XCTAssertEqual(try WidgetSupplementParser.air(data: data, selection: air).value, "Ni podatka")
    }

    func testSnowAndAirSelectionsAreRememberedIndependently() {
        let suite = "WidgetSupplementTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertEqual(WidgetSupplementSelection.read(from: defaults).kind, .sea)
        defaults.set("VOGEL", forKey: "widgetSnowStationID")
        defaults.set("Vogel", forKey: "widgetSnowStationName")
        defaults.set("E403", forKey: "widgetAirStationID")
        defaults.set("LJ Bežigrad", forKey: "widgetAirStationName")
        defaults.set("snow", forKey: "widgetSupplementKind")
        XCTAssertEqual(WidgetSupplementSelection.read(from: defaults), snow)
        defaults.set("air", forKey: "widgetSupplementKind")
        XCTAssertEqual(WidgetSupplementSelection.read(from: defaults), air)
        XCTAssertNotEqual(snow.cacheKey, air.cacheKey)
        defaults.set("snow", forKey: "widgetSupplementKind")
        XCTAssertEqual(WidgetSupplementSelection.read(from: defaults), snow)
    }

    func testUnselectedStationPromptsSelection() {
        let selection = WidgetSupplementSelection(kind: .snow, stationID: "", stationName: "")
        XCTAssertEqual(selection.unavailable.value, "Izberi postajo")
    }

    func testOldMeasurementIsMarkedAsOlder() {
        let result = WidgetSupplementValue(kind: .air, stationName: "LJ Bežigrad", value: "PM10 12 µg/m³", measuredAt: .now.addingTimeInterval(-13 * 3600))
        XCTAssertTrue(result.text.contains("starejše"))
    }
}
