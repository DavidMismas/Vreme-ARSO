import XCTest
@testable import Vreme_ARSO

final class ARSOWaterTemperaturesServiceTests: XCTestCase {
    func testCoastParsingBuildsSeaTemperatureSlots() throws {
        let data = try FixtureLoader.data(named: "water_coast_sample.html")
        let service = ARSOWaterTemperaturesService(apiClient: MockAPIClient())

        let slots = try service.parseCoastSlots(from: data)

        XCTAssertEqual(slots.count, 3)
        XCTAssertEqual(slots.first?.label, "Če 07 CET")
        XCTAssertEqual(slots.first?.seaTemperature, "11 °C")
        XCTAssertEqual(slots.first?.seaState, "2")
        XCTAssertEqual(slots.first?.windSpeed, "36 .. 54 km/h")
    }

    func testOverviewParsingReadsUnavailableMessage() throws {
        let data = try FixtureLoader.data(named: "water_overview_sample.html")
        let service = ARSOWaterTemperaturesService(apiClient: MockAPIClient())

        let message = try service.parseStatusMessage(from: data)

        XCTAssertEqual(message, "Temperature rek, jezer in morja začasno niso dosegljive.")
    }
}

private struct MockAPIClient: APIClientProtocol {
    func response(for endpoint: Endpoint) async throws -> APIResponse {
        throw ARSOError.noData
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        throw ARSOError.noData
    }
}
