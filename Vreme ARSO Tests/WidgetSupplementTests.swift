import XCTest
@testable import Vreme_ARSO

final class WidgetSupplementTests: XCTestCase {
    private let snow = WidgetSupplementSelection(kind: .snow, stationID: SnowStationReading.identifier(for: "Vogel"), stationName: "Vogel")
    private let air = WidgetSupplementSelection(kind: .air, stationID: "E403", stationName: "LJ Bežigrad")
    private let snapshotDate = DateFormatterSI.arsoXMLWithoutZone.date(from: "21.10.2026 10:00")!

    func testCurrentARSOTablesProvideRealSnowValuesAndPreserveMissingData() throws {
        let automatic = try FixtureLoader.data(named: "snow_automatic_2026-10-21.html")
        let manual = try FixtureLoader.data(named: "snow_manual_2026-10-21.html")
        let readings = SnowObservationHTMLParser.parse(automaticData: automatic, manualData: manual, now: snapshotDate)
        XCTAssertEqual(readings.first(where: { $0.name == "Vogel" })?.depthCentimeters, 0)
        XCTAssertEqual(readings.first(where: { $0.name == "Kredarica" })?.depthCentimeters, 0)
        XCTAssertNil(readings.first(where: { $0.name == "Kanin" }))
        XCTAssertEqual(readings.first(where: { $0.name == "Vogel" })?.isAutomatic, true)
    }

    func testOldSnowFeedIsRejectedEvenWhenItContainsNumbers() {
        let stale = Data("<table class=\"meteoSI-table\"><tr><th>05.12.2022 07:00 CET</th></tr><tr><td>Vogel</td><td>1515 m</td><td>48 cm</td></tr></table>".utf8)
        XCTAssertTrue(SnowObservationHTMLParser.parse(automaticData: stale, manualData: nil, now: snapshotDate).isEmpty)
    }

    func testWidgetUsesSelectedStationAndMigratesOldStationIDByName() throws {
        let automatic = try FixtureLoader.data(named: "snow_automatic_2026-10-21.html")
        let manual = try FixtureLoader.data(named: "snow_manual_2026-10-21.html")
        let oldSelection = WidgetSupplementSelection(kind: .snow, stationID: "VOGEL_", stationName: "Vogel")
        XCTAssertEqual(WidgetSupplementParser.snow(automaticData: automatic, manualData: manual, selection: oldSelection, now: snapshotDate).value, "0 cm")
        let unknown = WidgetSupplementSelection(kind: .snow, stationID: "OTHER", stationName: "Drug kraj")
        XCTAssertEqual(WidgetSupplementParser.snow(automaticData: automatic, manualData: manual, selection: unknown, now: snapshotDate).value, "Ni podatka")
    }

    func testSkiReportUsesSameCurrentARSOReadingsAsWidget() async throws {
        let automatic = try FixtureLoader.data(named: "snow_automatic_2026-10-21.html")
        let manual = try FixtureLoader.data(named: "snow_manual_2026-10-21.html")
        let service = ARSOSkiConditionsService(apiClient: SnowFixtureAPIClient(automatic: automatic, manual: manual), xmlParser: XMLParserService())
        let report = try await service.fetchReport(now: snapshotDate)
        XCTAssertEqual(report.locations.first(where: { $0.name == "Vogel" })?.snowDepthCentimeters, 0)
        XCTAssertEqual(report.locations.first(where: { $0.name == "Kredarica" })?.snowDepthCentimeters, 0)
        XCTAssertNil(report.locations.first(where: { $0.name == "Kanin" }))
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
        defaults.set(snow.stationID, forKey: "widgetSnowStationID")
        defaults.set("Vogel", forKey: "widgetSnowStationName")
        defaults.set("E403", forKey: "widgetAirStationID")
        defaults.set("LJ Bežigrad", forKey: "widgetAirStationName")
        defaults.set("snow", forKey: "widgetSupplementKind")
        XCTAssertEqual(WidgetSupplementSelection.read(from: defaults), snow)
        defaults.set("air", forKey: "widgetSupplementKind")
        XCTAssertEqual(WidgetSupplementSelection.read(from: defaults), air)
        defaults.set("snow", forKey: "widgetSupplementKind")
        XCTAssertEqual(WidgetSupplementSelection.read(from: defaults), snow)
    }

    func testUnselectedStationPromptsSelection() {
        let selection = WidgetSupplementSelection(kind: .snow, stationID: "", stationName: "")
        XCTAssertEqual(selection.unavailable.value, "Izberi postajo")
    }
}


private struct SnowFixtureAPIClient: APIClientProtocol {
    let automatic: Data
    let manual: Data

    func response(for endpoint: Endpoint) async throws -> APIResponse { throw ARSOError.noData }

    func data(for endpoint: Endpoint) async throws -> Data {
        switch endpoint {
        case .snowAutomaticObservations: automatic
        case .snowManualObservations: manual
        default: throw ARSOError.noData
        }
    }
}
