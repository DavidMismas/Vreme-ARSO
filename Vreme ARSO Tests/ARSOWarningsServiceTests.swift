import XCTest
@testable import Vreme_ARSO

final class ARSOWarningsServiceTests: XCTestCase {
    func testCAPParsingProducesWarningItem() throws {
        let data = try FixtureLoader.data(named: "warning_sample.xml")
        let root = try XMLParserService().parse(data: data)

        let info = try XCTUnwrap(root.children(named: "info").first)
        let item = WarningItem(
            id: root.textValue(forChild: "identifier") ?? "missing",
            title: info.textValue(forChild: "headline") ?? "",
            severity: .moderate,
            area: info.firstChild(named: "area")?.textValue(forChild: "areaDesc") ?? "",
            validFrom: DateFormatterSI.parseCAP(info.textValue(forChild: "onset")),
            validTo: DateFormatterSI.parseCAP(info.textValue(forChild: "expires")),
            body: info.textValue(forChild: "description") ?? "",
            eventType: "1; wind",
            polygons: info.firstChild(named: "area")?.children(named: "polygon").compactMap { polygon in
                polygon.text.split(separator: " ").compactMap { pair in
                    let components = pair.split(separator: ",")
                    guard let lat = components.first, let lon = components.last,
                          let latitude = Double(lat), let longitude = Double(lon) else { return nil }
                    return CoordinatePoint(latitude: latitude, longitude: longitude)
                }
            } ?? []
        )

        XCTAssertEqual(item.title, "Veter - zmerna ogroženost (Stopnja 2/4) - Slovenija / osrednja")
        XCTAssertEqual(item.area, "Slovenija / osrednja")
        XCTAssertEqual(item.severity, .moderate)
        XCTAssertEqual(item.polygons.first?.count, 3)
    }
}
