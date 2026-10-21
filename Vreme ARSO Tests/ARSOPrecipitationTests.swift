import CoreLocation
import XCTest
@testable import Vreme_ARSO

final class ARSOPrecipitationTests: XCTestCase {
    private let snapshotDate = DateFormatterSI.parseARSODate("21.10.2026 17:10 CEST")!

    func testLiveARSOSampleContainsMeasuredRainfallAndValidZero() throws {
        let data = try FixtureLoader.data(named: "precipitation_automatic_2026-10-21.xml")
        let stations = try ARSOPrecipitationParser.parse(data: data, now: snapshotDate)
        let ljubljana = stations.first { $0.reading.stationName == "Ljubljana" }?.reading
        XCTAssertEqual(ljubljana?.amountMillimeters, 16.41)
        XCTAssertEqual(ljubljana?.periodLabel, "Padavine od 8.00")
        XCTAssertEqual(stations.first { $0.reading.stationName == "Vogel" }?.reading.amountMillimeters, 36.96)
        XCTAssertEqual(stations.first { $0.reading.stationName == "Gačnik" }?.reading.amountMillimeters, 0)
    }

    func testStaleAndMissingMeasurementsAreNotPresentedAsCurrent() throws {
        let data = try FixtureLoader.data(named: "precipitation_automatic_2026-10-21.xml")
        XCTAssertTrue(try ARSOPrecipitationParser.parse(data: data, now: snapshotDate.addingTimeInterval(4 * 3600)).isEmpty)
        let empty = Data("<data><metData><domain_meteosiId>A</domain_meteosiId><domain_longTitle>Test</domain_longTitle><domain_lat>46</domain_lat><domain_lon>14</domain_lon><valid>21.10.2026 17:00 CEST</valid><tp_12h_acc/></metData></data>".utf8)
        XCTAssertTrue(try ARSOPrecipitationParser.parse(data: empty, now: snapshotDate).isEmpty)
    }

    func testStationListIncludesStationsWithoutCurrentMeasurement() throws {
        let data = Data("""
        <data>
          <metData><domain_meteosiId>A</domain_meteosiId><domain_longTitle>Postaja A</domain_longTitle><domain_lat>46</domain_lat><domain_lon>14</domain_lon><valid>21.10.2026 17:00 CEST</valid><tp_12h_acc>0</tp_12h_acc></metData>
          <metData><domain_meteosiId>B</domain_meteosiId><domain_longTitle>Postaja B</domain_longTitle><domain_lat>46</domain_lat><domain_lon>15</domain_lon><valid>21.10.2026 17:00 CEST</valid><tp_12h_acc/></metData>
        </data>
        """.utf8)
        let stations = try ARSOPrecipitationParser.parseStations(data: data, now: snapshotDate)
        XCTAssertEqual(stations.count, 2)
        XCTAssertEqual(stations.first { $0.id == "A" }?.reading?.amountMillimeters, 0)
        XCTAssertNil(stations.first { $0.id == "B" }?.reading)
        XCTAssertEqual(try ARSOPrecipitationParser.parse(data: data, now: snapshotDate).count, 1)
    }

    func testSelectedLocationUsesNearbyStationAndKeepsAttribution() async throws {
        let data = try FixtureLoader.data(named: "precipitation_automatic_2026-10-21.xml")
        let service = ARSOPrecipitationService(apiClient: PrecipitationFixtureAPIClient(data: data))
        let ljubljana = ResolvedForecastLocation(
            displayName: "Ljubljana", detailText: nil, source: .manualPlace,
            coordinate: CLLocationCoordinate2D(latitude: 46.06, longitude: 14.51),
            nearestStation: nil, observation: nil
        )
        let reading = try await service.reading(near: ljubljana, now: snapshotDate)
        XCTAssertEqual(reading?.stationName, "Ljubljana")
        XCTAssertEqual(reading?.amountMillimeters, 16.41)
        let distant = ResolvedForecastLocation(
            displayName: "Tujina", detailText: nil, source: .manualPlace,
            coordinate: CLLocationCoordinate2D(latitude: 48.2, longitude: 16.3),
            nearestStation: nil, observation: nil
        )
        let distantReading = try await service.reading(near: distant, now: snapshotDate)
        XCTAssertNil(distantReading)
    }
}

private struct PrecipitationFixtureAPIClient: APIClientProtocol {
    let data: Data
    func response(for endpoint: Endpoint) async throws -> APIResponse { throw ARSOError.noData }
    func data(for endpoint: Endpoint) async throws -> Data { data }
}
