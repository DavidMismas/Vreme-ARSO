import XCTest
@testable import Vreme_ARSO

final class ARSOObservationFeedMapperTests: XCTestCase {
    func testMapperBuildsStationsAndObservations() throws {
        let data = try FixtureLoader.data(named: "observation_sample.xml")
        let root = try XMLParserService().parse(data: data)

        let result = ARSOObservationFeedMapper().map(root: root)

        XCTAssertEqual(result.stations.count, 2)
        XCTAssertEqual(result.observations.count, 2)
        XCTAssertEqual(result.stations.first?.name, "Ljubljana")
        XCTAssertEqual(result.observations.first?.temperature, 12)
    }

    func testMapperToleratesMissingFields() throws {
        let data = try FixtureLoader.data(named: "observation_missing_fields.xml")
        let root = try XMLParserService().parse(data: data)

        let result = ARSOObservationFeedMapper().map(root: root)
        let observation = try XCTUnwrap(result.observations.first)

        XCTAssertEqual(result.stations.first?.name, "Katarina nad Ljubljano")
        XCTAssertEqual(observation.temperature, 8)
        XCTAssertNil(observation.windSpeed)
        XCTAssertNil(observation.precipitation)
        XCTAssertNil(observation.cloudiness)
    }
}
