import XCTest
@testable import Vreme_ARSO

final class ARSOLocationForecastServiceTests: XCTestCase {
    func testParseNearestLocationNameReadsTitle() throws {
        let data = """
        {
          "type": "Feature",
          "properties": {
            "title": "Ljubljana"
          }
        }
        """.data(using: .utf8)!

        let service = ARSOLocationForecastService(apiClient: MockLocationForecastAPIClient())

        let title = try service.parseNearestLocationName(from: data)

        XCTAssertEqual(title, "Ljubljana")
    }

    func testParseReportBuildsDailyCards() throws {
        let data = """
        {
          "forecast24h": {
            "features": [
              {
                "type": "Feature",
                "geometry": {
                  "type": "Point",
                  "coordinates": [14.5, 46.0]
                },
                "properties": {
                  "title": "Ljubljana",
                  "days": [
                    {
                      "date": "2026-03-20",
                      "timeline": [
                        {
                          "clouds_shortText_wwsyn_shortText": "pretežno oblačno",
                          "clouds_icon_wwsyn_icon": "prevCloudy_day",
                          "tnsyn": "2",
                          "txsyn": "12",
                          "ff_shortText": "šibek V",
                          "tp_24h_acc": "0.7"
                        }
                      ]
                    }
                  ]
                }
              }
            ]
          }
        }
        """.data(using: .utf8)!

        let service = ARSOLocationForecastService(apiClient: MockLocationForecastAPIClient())

        let report = try service.parseReport(
            from: data,
            resolvedLocationName: "Ljubljana",
            requestedLocationName: "Ljubljana"
        )

        XCTAssertEqual(report.locationName, "Ljubljana")
        XCTAssertEqual(report.days.count, 1)
        XCTAssertEqual(report.days.first?.summary, "pretežno oblačno")
        XCTAssertEqual(report.days.first?.weatherSymbol, "prevCloudy_day")
        XCTAssertEqual(report.days.first?.minTemperature, 2)
        XCTAssertEqual(report.days.first?.maxTemperature, 12)
        XCTAssertEqual(report.days.first?.windDescription, "šibek V")
        XCTAssertEqual(report.days.first?.precipitationAmount, 0.7)
    }
}

private struct MockLocationForecastAPIClient: APIClientProtocol {
    func response(for endpoint: Endpoint) async throws -> APIResponse {
        throw ARSOError.noData
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        throw ARSOError.noData
    }
}
