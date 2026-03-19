import XCTest
@testable import Vreme_ARSO

final class ARSOMountainConditionsServiceTests: XCTestCase {
    func testMountainParsingBuildsLocationWithTopAndBottomConditions() throws {
        let data = try FixtureLoader.data(named: "mountain_sample.html")
        let service = ARSOMountainConditionsService(apiClient: MockMountainAPIClient())

        let locations = try service.parseLocations(from: data)

        XCTAssertEqual(locations.count, 1)
        XCTAssertEqual(locations.first?.name, "BOHINJ")
        XCTAssertEqual(locations.first?.topElevation, "na vrhu: 533m")
        XCTAssertEqual(locations.first?.bottomElevation, "spodaj: 320m")
        XCTAssertEqual(locations.first?.slots.first?.topTemperature, "6 °C")
        XCTAssertEqual(locations.first?.slots.first?.bottomTemperature, "8 °C")
        XCTAssertEqual(locations.first?.slots.first?.topConditionSymbol, "clear")
        XCTAssertEqual(locations.first?.slots.first?.bottomConditionSymbol, "clear")
    }
}

private struct MockMountainAPIClient: APIClientProtocol {
    func response(for endpoint: Endpoint) async throws -> APIResponse {
        throw ARSOError.noData
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        throw ARSOError.noData
    }
}
